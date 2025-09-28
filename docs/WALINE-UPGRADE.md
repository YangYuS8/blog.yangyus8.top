# Waline 升级与配置指引

> 本站暂无生产评论数据，可直接重建。

## 版本线说明

Waline 目前“服务端”仍是 `1.x` 版本；“客户端”(@waline/client) 已发布到 `v3`。Docker Hub 上没有 `3.x` 镜像是正常现象——升级到 v3 主要指前端客户端资源升级。

## 当前策略

1. 使用官方 `lizheming/waline:latest` 作为服务端 (ThinkJS) 容器。
2. 前端加载 `@waline/client@v3` 的 ESM 资源。
3. 数据库存储使用 MariaDB。

## 环境变量要点

| 目的 | MariaDB 官方镜像 | Waline 服务端读取 |
|------|------------------|-------------------|
| 数据库名称 | `MYSQL_DATABASE` | `MYSQL_DB` |

本仓库通过 `docker-compose.yml` 中：

```yaml
waline:
  environment:
    MYSQL_DB: ${MYSQL_DATABASE}
```

实现变量映射，因此只需在 `.env` 里维护 `MYSQL_DATABASE`。

必填变量 (在 `.env` 中设置)：

```
MYSQL_ROOT_PASSWORD=...
MYSQL_DATABASE=waline
MYSQL_USER=waline
MYSQL_PASSWORD=...
```

可选：
- `ADMIN_USER` / `ADMIN_PASSWORD` (首次后台登录)
- 邮件通知相关 `SMTP_*`

## 升级客户端到 v3 的注意点

1. CDN / 资源：
   ```html
   <link rel="stylesheet" href="https://unpkg.com/@waline/client@v3/dist/waline.css" />
   <script type="module">
     import { init } from 'https://unpkg.com/@waline/client@v3/dist/waline.js';
     init({
       el: '#waline',
       serverURL: 'https://blog.yangyus8.top/comment/',
       path: window.location.pathname,
     });
   </script>
   ```
2. CSS 变量变更：`--waline-bgcolor` → `--waline-bg-color` 等 (若有自定义覆盖须同步)。
3. 仅支持现代浏览器 & Node 18/20（客户端层面）。

## 重建流程

```
# 1. 确认/修改 .env
cp .env.example .env  # 如未创建
vi .env               # 填入真实密码

# 2. 启动或重建
docker compose up -d --force-recreate waline waline-db

# 3. 查看日志确认未再回退 LeanCloud
docker logs -f waline | grep -i mysql

# 4. 探针
curl -i "https://blog.yangyus8.top/comment/api/comment?path=/&pageSize=1"

# 5. 重新生成站点 (若改了模板或配置)
hexo clean && hexo generate
```

## 可选：自建 Node 20 基础的 Waline 镜像

官方镜像产生 `punycode` 弃用警告，可通过自建镜像 (Node 20) 消除：

```Dockerfile
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache git \
 && git clone --depth=1 https://github.com/walinejs/waline.git .
# 如果仓库结构更新，请根据 packages/server 实际构建指令调整：
RUN corepack enable && pnpm install --filter @waline/server --prod

FROM node:20-alpine
WORKDIR /app
COPY --from=base /app/packages/server /app
ENV NODE_ENV=production
EXPOSE 8360
CMD ["node","bin/waline","start"]
```

构建并替换：
```
docker build -t your-registry/waline:node20 -f Dockerfile.waline .
docker push your-registry/waline:node20
# 修改 docker-compose.yml 中 waline 的 image。
```

## 回滚策略

若升级后前端异常：
1. 恢复旧生成文件或回滚到上一个 git commit。
2. 清理浏览器缓存 (加查询参数 `?v=ts`)。
3. 如为自建镜像问题，换回 `lizheming/waline:latest`。

## 故障排查速查表

| 现象 | 可能原因 | 快速检查 |
|------|----------|----------|
| `Not initialized` LeanCloud 栈 | 未识别 MySQL | `docker exec waline env | grep MYSQL_DB` |
| 500 接口 + ER_ACCESS_DENIED | 用户/密码错误 | 连接 MariaDB: `mariadb -u root -p` 查看权限 |
| 前端无评论区域 | 模板未注入/JS 报错 | 浏览器控制台 Network/Console |
| CSS 变量失效 | 仍使用旧变量名 | DevTools Elements -> Computed 过滤 `--waline-` |

---

如需进一步全自动化（CI 构建自定义 Waline 镜像 + 推送），可再补充 GitHub Actions 工作流。欢迎继续提需求。
