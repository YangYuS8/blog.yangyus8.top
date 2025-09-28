# Makefile for Hexo + Docker Deployment
# 使用: make <target>
# 若使用 zsh/bash: TAB 补全可查看可用命令

# ================= 基础变量 =================
SHELL := /bin/bash
HEXO := npx hexo
# 镜像命名参数（可通过 make OWNER=xxx IMAGE_NAME=xxx IMAGE_TAG=xxx 覆盖）
OWNER ?= yangyus8
IMAGE_NAME ?= blog
IMAGE_TAG ?= latest

# 组合默认镜像（符合 ghcr.io/<owner>/<name>:<tag> 规范；全部小写）
IMAGE ?= ghcr.io/$(OWNER)/$(IMAGE_NAME):$(IMAGE_TAG)

# 若环境提供 BLOG_IMAGE 则优先生效（避免之前使用 Bash 参数展开在 GNU Make 中被截断的问题）
ifdef BLOG_IMAGE
IMAGE := $(BLOG_IMAGE)
endif
DOCKER_COMPOSE := docker compose

# 默认目标
.DEFAULT_GOAL := help

# ================= 开发本地 =================
.PHONY: install
install: ## 安装依赖 (pnpm)
	pnpm install

.PHONY: clean
clean: ## 清理 Hexo 缓存与已生成文件
	$(HEXO) clean

.PHONY: build
build: ## 生成静态文件 (public/)
	$(HEXO) generate

.PHONY: serve
serve: ## 本地启动预览 http://localhost:4000
	$(HEXO) server

.PHONY: new
new: ## 新建文章: make new t="标题"
ifndef t
	@echo "用法: make new t=标题" && exit 1
endif
	$(HEXO) new post "$(t)"

# ================= 质量/调试 =================
## 保留最小必要集合


# ================= Docker 本地构建与运行 =================
.PHONY: docker-build
docker-build: ## 本地构建多阶段镜像 (不推送)
	@echo "[BUILD] 镜像: $(IMAGE)"
	docker build -t $(IMAGE) .

## 本地镜像快速运行（可按需启用）
.PHONY: docker-run
docker-run: docker-build ## 以本地镜像运行 (端口 8080)
	docker run --rm -p 8080:80 $(IMAGE)
	@echo "打开 http://localhost:8080"

# ================= 服务器相关（方案二） =================
.PHONY: update-local
update-local: ## （本地/内网服务器）拉取最新镜像并重启
	bash ops/update.sh

# ================= 重置 / 清空站点数据 =================
# ================= 数据库备份 =================
.PHONY: backup-db
backup-db: ## (已弃用) 旧 MariaDB 备份脚本占位，如不再使用可删除该目标
	bash ops/backup-db.sh

# Twikoo 预热（请求一次 API，降低首访延迟）
.PHONY: twikoo-warmup
twikoo-warmup: ## 预热 Twikoo （需服务器已启动 docker compose）
	@curl -s -o /dev/null -w 'Twikoo warmup TTFB=%{time_starttransfer}s TOTAL=%{time_total}s\n' $${TWIKOO_PUBLIC_URL:-https://blog.yangyus8.top/twikoo/} || true
.PHONY: twikoo-reset
twikoo-reset: ## 重置 Twikoo 副本集 (可选 PURGE=1 清空数据) 例: make twikoo-reset PURGE=1
	bash ops/twikoo-reset.sh

# ================= 按 abbrlink 删除单篇文章 =================

# ================= MinIO/对象存储（可选） =================
## MinIO 辅助命令按需启用
.PHONY: minio-up
minio-up:
	$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.minio.yml up -d

.PHONY: minio-init
minio-init:
	bash ops/init-minio.sh



# ================= 实用信息 =================
.PHONY: help
help: ## 显示所有可用目标
	@echo "可用命令:" && echo && \
	grep -E '^[a-zA-Z0-9_-]+:.*?##' Makefile | sort | awk 'BEGIN {FS":.*?##"}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' && echo && \
	echo "示例:" && \
	echo "  make new t=你好世界" && \
	echo "  make serve" && \
	echo "  make docker-build" && \
	echo "  make update-local"
