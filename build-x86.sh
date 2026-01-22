#!/bin/bash

# 跨平台构建脚本 - 为 x86 服务器构建镜像
# 用于在 Mac ARM64 上构建 x86_64 镜像

set -e

echo "=== DayUniApp H5 - 跨平台构建脚本 (x86) ==="
echo ""

# 配置变量
IMAGE_NAME="dayuniapp-h5"
IMAGE_TAG="latest-x86"
PLATFORM="linux/amd64"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 步骤 1: 检查 buildx
echo -e "${YELLOW}步骤 1: 检查 Docker buildx...${NC}"
if docker buildx version >/dev/null 2>&1; then
    echo -e "${GREEN}✓ buildx 已安装${NC}"
    docker buildx version
else
    echo -e "${RED}✗ buildx 未安装，请升级 Docker 版本${NC}"
    exit 1
fi
echo ""

# 步骤 2: 创建并启动 buildx builder
echo -e "${YELLOW}步骤 2: 创建 buildx 构建实例...${NC}"
BUILDER_NAME="dayuniapp-builder"

# 检查 builder 是否已存在
if docker buildx inspect ${BUILDER_NAME} >/dev/null 2>&1; then
    echo "使用已存在的 builder: ${BUILDER_NAME}"
else
    echo "创建新的 builder: ${BUILDER_NAME}"
    docker buildx create --name ${BUILDER_NAME} --driver docker-container --use
fi

# 启动 builder
docker buildx inspect ${BUILDER_NAME} --bootstrap
echo -e "${GREEN}✓ builder 准备就绪${NC}"
echo ""

# 步骤 3: 构建跨平台镜像
echo -e "${YELLOW}步骤 3: 构建 x86_64 镜像...${NC}"
echo "目标平台: ${PLATFORM}"
echo "镜像名称: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""

docker buildx build \
    --platform ${PLATFORM} \
    -t ${IMAGE_NAME}:${IMAGE_TAG} \
    --load \
    -f Dockerfile \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像构建成功${NC}"
    echo ""
    echo "镜像信息:"
    docker images | grep ${IMAGE_NAME}
    echo ""
    echo "架构信息:"
    docker inspect ${IMAGE_NAME}:${IMAGE_TAG} | grep -A 5 "Architecture"
else
    echo -e "${RED}✗ 镜像构建失败${NC}"
    exit 1
fi
echo ""

# 步骤 4: 本地测试（可选）
echo -e "${YELLOW}步骤 4: 是否进行本地测试?${NC}"
read -p "本地测试? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "启动本地测试容器..."
    CONTAINER_NAME="dayuniapp-h5-test-x86"
    HOST_PORT=8082

    # 停止旧容器
    if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
        docker stop ${CONTAINER_NAME} 2>/dev/null || true
        docker rm ${CONTAINER_NAME} 2>/dev/null || true
    fi

    # 运行新容器
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${HOST_PORT}:80 \
        ${IMAGE_NAME}:${IMAGE_TAG}

    echo "等待容器启动..."
    sleep 3

    # 检查状态
    if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        echo -e "${GREEN}✓ 容器运行成功${NC}"
        echo "访问地址: http://localhost:${HOST_PORT}"
        echo ""
        echo "查看日志: docker logs -f ${CONTAINER_NAME}"
        echo "停止容器: docker stop ${CONTAINER_NAME}"
    else
        echo -e "${RED}✗ 容器启动失败${NC}"
        docker logs ${CONTAINER_NAME}
    fi
fi
echo ""

# 完成
echo -e "${GREEN}=== 构建完成 ===${NC}"
echo ""
echo "📝 下一步操作:"
echo "  1. 本地测试: docker run -d -p 8082:80 ${IMAGE_NAME}:${IMAGE_TAG}"
echo "  2. 部署到服务器: ./deploy-to-server-x86.sh"
echo ""
echo "📦 镜像信息:"
echo "  名称: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "  平台: ${PLATFORM}"
echo "  大小: $(docker images ${IMAGE_NAME}:${IMAGE_TAG} --format "{{.Size}}")"
echo ""
