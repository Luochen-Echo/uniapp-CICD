#!/bin/bash

# DayUniApp H5 - 服务器部署脚本 (x86 版本)
# 用于将 x86 镜像传输到服务器并部署

set -e

echo "=== DayUniApp H5 - 服务器部署脚本 (x86) ==="
echo ""

# 配置变量
SERVER_IP="101.42.15.26"
SERVER_USER="root"
IMAGE_NAME="dayuniapp-h5"
IMAGE_TAG="latest-x86"
CONTAINER_NAME="dayuniapp-h5-prod"
HOST_PORT=9101
REMOTE_DIR="/opt/dayuniapp-h5"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查是否提供了服务器IP参数
if [ ! -z "$1" ]; then
    SERVER_USER_IP=$1
else
    SERVER_USER_IP="${SERVER_USER}@${SERVER_IP}"
fi

# 步骤 1: 检查镜像是否存在
echo -e "${YELLOW}步骤 1: 检查镜像...${NC}"
if docker images | grep -q "${IMAGE_NAME}.*${IMAGE_TAG}"; then
    echo -e "${GREEN}✓ 镜像存在${NC}"
    docker images | grep "${IMAGE_NAME}.*${IMAGE_TAG}"
else
    echo -e "${RED}✗ 镜像不存在，请先运行 ./build-x86.sh${NC}"
    exit 1
fi
echo ""

# 步骤 2: 创建输出目录
echo -e "${YELLOW}步骤 2: 创建输出目录...${NC}"
mkdir -p docker-dist
echo -e "${GREEN}✓ 目录创建成功${NC}"
echo ""

# 步骤 3: 导出 Docker 镜像
echo -e "${YELLOW}步骤 3: 导出 Docker 镜像...${NC}"
docker save ${IMAGE_NAME}:${IMAGE_TAG} -o docker-dist/${IMAGE_NAME}-${IMAGE_TAG}.tar

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像导出成功${NC}"
    ls -lh docker-dist/${IMAGE_NAME}-${IMAGE_TAG}.tar
else
    echo -e "${RED}✗ 镜像导出失败${NC}"
    exit 1
fi
echo ""

# 步骤 4: 在服务器上创建目录
echo -e "${YELLOW}步骤 4: 在服务器上创建目录...${NC}"
ssh ${SERVER_USER_IP} "mkdir -p ${REMOTE_DIR}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 目录创建成功${NC}"
else
    echo -e "${RED}✗ 目录创建失败${NC}"
    exit 1
fi
echo ""

# 步骤 5: 传输镜像文件
echo -e "${YELLOW}步骤 5: 传输镜像到服务器...${NC}"
echo "提示: 这可能需要几分钟，取决于网络速度"
scp docker-dist/${IMAGE_NAME}-${IMAGE_TAG}.tar ${SERVER_USER_IP}:${REMOTE_DIR}/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像传输成功${NC}"
else
    echo -e "${RED}✗ 镜像传输失败${NC}"
    exit 1
fi
echo ""

# 步骤 6: 生成服务器部署脚本
echo -e "${YELLOW}步骤 6: 生成服务器部署脚本...${NC}"
cat > docker-dist/deploy-on-server.sh <<'EOFSCRIPT'
#!/bin/bash

# 服务器端部署脚本

set -e

IMAGE_NAME="dayuniapp-h5"
IMAGE_TAG="latest-x86"
CONTAINER_NAME="dayuniapp-h5-prod"
HOST_PORT=9101
REMOTE_DIR="/opt/dayuniapp-h5"

echo "=== 服务器端部署 - DayUniApp H5 ==="
echo ""

# 停止并删除旧容器
if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo "停止并删除旧容器..."
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    echo "✓ 旧容器已清理"
fi

# 删除旧镜像（可选）
if docker images | grep -q "${IMAGE_NAME}.*${IMAGE_TAG}"; then
    echo "删除旧镜像..."
    docker rmi ${IMAGE_NAME}:${IMAGE_TAG} 2>/dev/null || true
fi

# 导入镜像
echo "导入 Docker 镜像..."
docker load -i ${REMOTE_DIR}/${IMAGE_NAME}-${IMAGE_TAG}.tar

if [ $? -eq 0 ]; then
    echo "✓ 镜像导入成功"
    docker images | grep "${IMAGE_NAME}.*${IMAGE_TAG}"
else
    echo "✗ 镜像导入失败"
    exit 1
fi

# 启动新容器
echo "启动新容器..."
docker run -d \
    --name ${CONTAINER_NAME} \
    --network ruoyi-prod-network \
    --restart unless-stopped \
    -p ${HOST_PORT}:80 \
    ${IMAGE_NAME}:${IMAGE_TAG}

# 等待容器启动
echo "等待容器启动..."
sleep 5

# 检查容器状态
if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "✓ 容器启动成功"
    docker ps | grep ${CONTAINER_NAME}
else
    echo "✗ 容器启动失败"
    echo "查看错误日志:"
    docker logs --tail 50 ${CONTAINER_NAME}
    exit 1
fi

echo ""
echo "=== 部署完成 ==="
echo ""
echo "🌐 访问地址:"
echo "   http://$(hostname -I | awk '{print $1'}):${HOST_PORT}"
echo ""
echo "📝 常用命令:"
echo "   查看日志: docker logs -f ${CONTAINER_NAME}"
echo "   重启容器: docker restart ${CONTAINER_NAME}"
echo "   停止容器: docker stop ${CONTAINER_NAME}"
echo "   进入容器: docker exec -it ${CONTAINER_NAME} sh"
echo ""
EOFSCRIPT

chmod +x docker-dist/deploy-on-server.sh
scp docker-dist/deploy-on-server.sh ${SERVER_USER_IP}:${REMOTE_DIR}/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 部署脚本传输成功${NC}"
else
    echo -e "${RED}✗ 部署脚本传输失败${NC}"
    exit 1
fi
echo ""

# 步骤 7: 在服务器上执行部署
echo -e "${YELLOW}步骤 7: 在服务器上执行部署...${NC}"
echo -e "${YELLOW}提示: 首次连接需要输入服务器密码${NC}"
ssh ${SERVER_USER_IP} "cd ${REMOTE_DIR} && bash deploy-on-server.sh"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 服务器部署成功${NC}"
else
    echo -e "${RED}✗ 服务器部署失败${NC}"
    exit 1
fi
echo ""

# 完成
echo -e "${GREEN}=== 部署完成 ===${NC}"
echo ""
echo "🌐 访问地址:"
echo "  http://${SERVER_IP}:${HOST_PORT}"
echo ""
echo "📝 服务器常用命令:"
echo "  SSH 登录: ssh ${SERVER_USER_IP}"
echo "  查看日志: ssh ${SERVER_USER_IP} 'docker logs -f ${CONTAINER_NAME}'"
echo "  重启服务: ssh ${SERVER_USER_IP} 'docker restart ${CONTAINER_NAME}'"
echo "  查看状态: ssh ${SERVER_USER_IP} 'docker ps | grep ${CONTAINER_NAME}'"
echo ""
