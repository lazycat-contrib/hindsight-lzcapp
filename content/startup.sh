#!/bin/sh
# LazyCat 启动包装：
# 1. 镜像以 root 覆写启动（user: root），先修正挂载目录属主
# 2. 降权回镜像原生用户 hindsight (UID/GID 1000) 后执行原始入口
# 说明：镜像为 rootless 设计（无 root 运行逻辑），pg0 数据目录必须
# 归 UID 1000 所有，否则内嵌 PostgreSQL 报 Permission denied。
set -e

PG0_DIR=/home/hindsight/.pg0
mkdir -p "$PG0_DIR"
chown -R 1000:1000 "$PG0_DIR"

# 降权并切换 HOME 后执行原 CMD（python:3.11-slim 基底自带 python3）
exec python3 -c 'import os
os.setgid(1000)
os.setgroups([])
os.setuid(1000)
os.environ["HOME"] = "/home/hindsight"
os.execv("/app/start-all.sh", ["/app/start-all.sh"])'
