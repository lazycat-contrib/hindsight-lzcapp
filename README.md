# Hindsight for LazyCat (hindsight-lzcapp)

[Hindsight](https://github.com/vectorize-io/hindsight) 打包为懒猫微服 LPK v2 应用：Agent 记忆系统（retain / recall / reflect），MIT 协议，Vectorize 出品。

## 包信息

- 包名：`community.lazycat.app.hindsight`
- 上游镜像：`ghcr.io/vectorize-io/hindsight`（GHCR，tag 为纯 semver，如 `0.10.0`）
- 交付方式：**mirror**（`ghcr.1ms.run` 加速器，digest 校验），仅发布**喵喵私有商店**
- 目标架构：amd64；`min_os_version: 1.5.0`

## 转换要点

| Docker Run | LPK |
|---|---|
| `-p 9999:9999`（UI 控制面） | `upstreams: / → http://hindsight:9999/`；控制面在容器内代理 API（`HINDSIGHT_CP_DATAPLANE_API_URL=http://localhost:8888`），单域即可用 |
| `-p 8888:8888`（API） | 不单独暴露；走同一子域名（网关鉴权）。客户端 `base_url` 指向应用域名即可 |
| `-v hindsight-data:/home/hindsight/.pg0` | `binds: /lzcapp/var/data:/home/hindsight/.pg0`（内嵌 PostgreSQL 数据） |
| rootless 镜像（USER 1000） | `user: root` + `content/startup.sh`：先 `chown 1000:1000` 挂载目录，再经 python 降权回 UID 1000 执行 `/app/start-all.sh`（不依赖 lzcos 1.6.0 的 `run_as`） |
| `-e HINDSIGHT_API_LLM_API_KEY` | 设置向导 7 个参数（LLM 服务商/Key/模型/接口地址 + 可选视觉模型组） |

## 部署参数

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `llm_provider` | string | `openai` | 支持 openai、anthropic、gemini、groq、deepseek、zai、minimax、ollama、lmstudio 及 OpenAI 兼容网关 |
| `llm_api_key` | secret | 空 | 本地/订阅制服务商可留空 |
| `llm_model` | string | `gpt-4o-mini` | 模型标识 |
| `llm_base_url` | string | 空 | 可选，自定义 OpenAI 兼容接口地址 |
| `vlm_provider` / `vlm_model` / `vlm_api_key` | string/secret | 空 | 可选，图片附件走独立视觉模型 |

其余 200+ 环境变量（reranker、embeddings、admission 控制等）见上游 `.env.example`，本包未暴露到向导。

## 本地构建与验证

```sh
lzc-cli project release
lzc-cli lpk info dist/*.lpk
```

## 自动发布（仅喵喵商店）

`.github/workflows/lazycat.yml` 每日 04:37 UTC（或手动触发）：

1. 检查 `ghcr.io/vectorize-io/hindsight` 新的 `X.Y.Z` tag（`tag_regex: ^\d+\.\d+\.\d+$`）
2. 校验 `ghcr.1ms.run` 镜像 digest 与源一致（`require_digest_match: true`），更新 manifest 与版本
3. 构建 LPK → 提交 → 打 tag → GitHub Release（`community.lazycat.app.hindsight-v<version>.lpk`）
4. 发布到喵喵私有商店

所需 Secrets：`APPSTORE_URL`、`APPSTORE_TOKEN`（必填），`APP_ID`、`PRIVATE_STORE_GROUP_CODES`（可选）。组织级已配置。
