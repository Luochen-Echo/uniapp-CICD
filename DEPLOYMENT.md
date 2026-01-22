# DayUniApp H5 部署指南

> 本文档介绍如何将 DayUniApp H5 前端项目部署到 CentOS 服务器

---

## 📋 目录

- [项目信息](#项目信息)
- [部署架构](#部署架构)
- [本地测试](#本地测试)
- [服务器部署](#服务器部署)
- [常见问题](#常见问题)
- [维护操作](#维护操作)

---

## 项目信息

### 技术栈
- **前端框架**: Vue 3 + Vite
- **UI 库**: Vant 4
- **状态管理**: Pinia
- **路由**: Vue Router 4
- **HTTP**: Axios
- **容器**: Docker + Nginx

### 环境配置
- **本地开发**: http://localhost:3000
- **生产环境**: http://101.42.15.26:9101
- **后端 API**: http://101.42.15.26:9100

### 端口映射
| 服务 | 容器端口 | 主机端口 | 说明 |
|------|---------|---------|------|
| 前端 | 80 | 9101 | Nginx Web 服务 |

---

## 部署架构

```
┌─────────────────────────────────────────────────────┐
│                    本地 Mac                          │
│  ┌──────────────────────────────────────────────┐  │
│  │  npm run build (构建)                        │  │
│  │  ↓                                           │  │
│  │  dist/ (静态文件)                            │  │
│  │  ↓                                           │  │
│  │  Docker 镜像构建                              │  │
│  │  dayuniapp-h5:latest (约 20MB)              │  │
│  └──────────────────────────────────────────────┘  │
│                       │                             │
│                       │ scp 传输                    │
│                       ▼                             │
┌─────────────────────────────────────────────────────┐
│              CentOS 7 服务器                         │
│  ┌──────────────────────────────────────────────┐  │
│  │  Docker 容器                                  │  │
│  │  dayuniapp-h5-prod                           │  │
│  │  ↓                                           │  │
│  │  Nginx (80端口) → 主机 9101 端口             │  │
│  └──────────────────────────────────────────────┘  │
│         │                                            │
│         │ API 代理                                   │
│         ▼                                            │
│  ┌──────────────────────────────────────────────┐  │
│  │  后端服务 (已运行)                            │  │
│  │  http://101.42.15.26:9100                    │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
         │
         ▼
  用户访问: http://101.42.15.26:9101
```

---

## 本地测试

### 1. 设置脚本执行权限

```bash
chmod +x build-and-test.sh
chmod +x deploy-to-server.sh
```

### 2. 构建并本地测试

```bash
./build-and-test.sh
```

这个脚本会自动:
1. 清理旧容器
2. 构建 Docker 镜像
3. 启动测试容器
4. 检查容器状态
5. 测试访问

### 3. 本地访问

打开浏览器访问: http://localhost:9101

### 4. 查看日志

```bash
docker logs -f dayuniapp-h5-test
```

### 5. 停止测试容器

```bash
docker stop dayuniapp-h5-test
docker rm dayuniapp-h5-test
```

---

## 服务器部署

### 方式一: 使用自动部署脚本(推荐)

```bash
# 使用默认配置 (101.42.15.26)
./deploy-to-server.sh

# 或指定服务器用户和IP
./deploy-to-server.sh root@your-server-ip
```

这个脚本会自动:
1. 导出 Docker 镜像
2. 创建服务器目录
3. 传输镜像到服务器
4. 传输部署脚本
5. 在服务器上执行部署

### 方式二: 手动部署

#### 步骤 1: 构建镜像

```bash
docker build -t dayuniapp-h5:latest .
```

#### 步骤 2: 导出镜像

```bash
mkdir -p docker-dist
docker save dayuniapp-h5:latest -o docker-dist/dayuniapp-h5-latest.tar
```

#### 步骤 3: 传输到服务器

```bash
scp docker-dist/dayuniapp-h5-latest.tar root@101.42.15.26:/opt/dayuniapp-h5/
```

#### 步骤 4: 在服务器上导入并运行

```bash
# SSH 登录服务器
ssh root@101.42.15.26

# 创建目录
mkdir -p /opt/dayuniapp-h5
cd /opt/dayuniapp-h5

# 导入镜像
docker load -i dayuniapp-h5-latest.tar

# 停止并删除旧容器(如果存在)
docker stop dayuniapp-h5-prod 2>/dev/null || true
docker rm dayuniapp-h5-prod 2>/dev/null || true

# 启动新容器
docker run -d \
    --name dayuniapp-h5-prod \
    --restart unless-stopped \
    -p 9101:80 \
    dayuniapp-h5:latest
```

#### 步骤 5: 验证部署

```bash
# 检查容器状态
docker ps | grep dayuniapp-h5-prod

# 查看日志
docker logs dayuniapp-h5-prod

# 测试访问
curl -I http://localhost:9101
```

---

## 常见问题

### 问题 1: 端口被占用

**错误信息**:
```
Bind for 0.0.0.0:9101 failed: port is already allocated
```

**解决方案**:

```bash
# 查看端口占用
netstat -tuln | grep 9101
lsof -i :9101

# 停止占用端口的容器
docker stop $(docker ps -q -f publish=9101)

# 或修改端口映射
docker run -d --name dayuniapp-h5-prod -p 8083:80 dayuniapp-h5:latest
```

### 问题 2: API 请求失败

**症状**: 前端页面可以访问,但 API 请求失败

**检查**:

```bash
# 检查后端服务是否运行
curl http://101.42.15.26:9100/docs

# 检查 Nginx 配置
docker exec dayuniapp-h5-prod cat /etc/nginx/conf.d/default.conf

# 检查容器日志
docker logs dayuniapp-h5-prod
```

**解决方案**:

1. 确认后端服务正常运行
2. 检查 `nginx.conf` 中的 API 代理配置
3. 重新构建镜像并部署

### 问题 3: 页面 404 或空白

**可能原因**:

1. Vue Router History 模式配置问题
2. 构建文件未正确复制

**检查**:

```bash
# 检查构建文件
docker exec dayuniapp-h5-prod ls -lh /usr/share/nginx/html/

# 检查 Nginx 配置
docker exec dayuniapp-h5-prod cat /etc/nginx/conf.d/default.conf
```

### 问题 4: 防火墙阻止访问

**症状**: 服务器内可以访问,外部无法访问

**解决方案**:

```bash
# 开放防火墙端口
firewall-cmd --permanent --add-port=9101/tcp
firewall-cmd --reload

# 验证
firewall-cmd --list-ports
```

### 问题 5: SELinux 阻止

**症状**: 容器无法启动或访问文件

**检查**:

```bash
getenforce
```

**解决方案**:

```bash
# 临时设置为 Permissive 模式
setenforce 0

# 永久禁用(如果需要)
vi /etc/selinux/config
# 将 SELINUX=enforcing 改为 SELINUX=disabled
```

---

## 维护操作

### 查看日志

```bash
# 实时查看日志
docker logs -f dayuniapp-h5-prod

# 查看最近 100 行
docker logs --tail 100 dayuniapp-h5-prod
```

### 重启容器

```bash
docker restart dayuniapp-h5-prod
```

### 停止容器

```bash
docker stop dayuniapp-h5-prod
```

### 删除容器

```bash
docker stop dayuniapp-h5-prod
docker rm dayuniapp-h5-prod
```

### 更新部署

```bash
# 本地重新构建
docker build -t dayuniapp-h5:latest .

# 重新部署
./deploy-to-server.sh
```

### 进入容器调试

```bash
docker exec -it dayuniapp-h5-prod sh
```

### 查看容器资源使用

```bash
docker stats dayuniapp-h5-prod
```

### 备份镜像

```bash
# 在服务器上
docker save dayuniapp-h5:latest | gzip > dayuniapp-h5-backup-$(date +%Y%m%d).tar.gz
```

---

## 配置文件说明

### Dockerfile
- 构建阶段: 使用 Node.js 18 构建 Vue 项目
- 生产阶段: 使用 Nginx Alpine 托管静态文件
- 镜像大小: 约 20-30 MB

### nginx.conf
- 监听 80 端口(容器内部)
- API 代理: `/api/*` → `http://101.42.15.26:9100/`
- 静态资源缓存: 1 年
- Gzip 压缩: 启用
- Vue Router 支持: History 模式

### .dockerignore
排除不必要的文件,减小镜像大小:
- node_modules
- dist
- 编辑器配置
- Git 文件
- 日志文件

---

## 部署检查清单

### 部署前检查

- [ ] 本地构建测试通过
- [ ] 后端 API 正常运行
- [ ] 服务器端口 9101 未被占用
- [ ] 服务器 Docker 已安装
- [ ] 防火墙已配置(如需外部访问)

### 部署后验证

- [ ] 容器状态为 Up
- [ ] 可以访问前端页面
- [ ] API 代理正常工作
- [ ] 浏览器控制台无错误
- [ ] 所有页面路由正常

---

## 快速参考

### 本地命令

```bash
# 构建并测试
./build-and-test.sh

# 手动构建
docker build -t dayuniapp-h5:latest .

# 本地运行
docker run -d --name dayuniapp-h5-test -p 9101:80 dayuniapp-h5:latest
```

### 服务器命令

```bash
# SSH 登录
ssh root@101.42.15.26

# 查看容器
docker ps | grep dayuniapp-h5

# 查看日志
docker logs -f dayuniapp-h5-prod

# 重启服务
docker restart dayuniapp-h5-prod
```

### URL 地址

| 环境 | URL |
|------|-----|
| 本地开发 | http://localhost:3000 |
| 本地测试 | http://localhost:9101 |
| 生产环境 | http://101.42.15.26:9101 |
| 后端 API | http://101.42.15.26:9100 |
| API 文档 | http://101.42.15.26:9100/docs |

---

## 总结

本文档提供了 DayUniApp H5 项目的完整部署方案:

1. ✅ **本地测试**: 使用 `build-and-test.sh` 进行本地构建和测试
2. ✅ **自动部署**: 使用 `deploy-to-server.sh` 一键部署到服务器
3. ✅ **手动部署**: 提供详细的手动部署步骤
4. ✅ **问题排查**: 列出常见问题和解决方案
5. ✅ **维护操作**: 日常运维命令参考

**部署时间**:
- 首次: 约 5-10 分钟
- 更新: 约 2-3 分钟

**成功标志**:
- 容器状态为 Up
- 可以通过浏览器访问 http://101.42.15.26:9101
- API 请求正常响应

---

**文档版本**: v1.0
**更新日期**: 2026-01-22
**项目**: DayUniApp H5
**维护者**: Server Team


Zw25d8e572