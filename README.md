# gemini-web2api-easy (deploy)

在单个容器(Render 免费层)内把 **gemini-web2api-go** 与 **easy_proxies** 二合一部署的官方配置。

## 架构

```
Render 公开入口:8083
  │
gemini-web2api-go  (0.0.0.0:8083, OpenAI-compatible API /v1/* , /admin)
  │  --proxy http://127.0.0.1:2323
easy_proxies (pool 模式, 127.0.0.1:2323, 内部出站)
  │  订阅(经 EASY_SUB_URL 注入)聚合多协议节点 + 健康检查 + 故障转移
  └─→ 上游 (vless/ss/trojan/hy2/socks5/https...)
```

## 文件

- `Dockerfile` — 多段构建:easy_proxies(官方 6 tags 静态编译)+ gemini-web2api-go(静态)+ debian bookworm-slim 运行时
- `config-easy.yaml` — easy_proxies pool 模式,监听 `127.0.0.1:2323`,订阅 URL 由启动脚本注入
- `start.sh` — 注入 `EASY_SUB_URL` 到配置 → 后台起 easy_proxies → exec 前台 gemini
- `render.yaml` — Render Blueprint(免费层 Web Service + 1GB 磁盘 + secret env)

## 部署到 Render

1. 把本仓库推向 GitHub
2. Render → **New → Blueprint** → 连接本仓库
3. 选 `deploy/render.yaml` → Apply
4. 在 Web Service 的 **Env** 查看生成的 `ADMIN_TOKEN` / `API_KEY`
5. `EASY_SUB_URL` 默认指向 `https://234.qzz.io/fsllist64`,改订阅 = 编辑此 env → Redeploy

## 验证

```bash
curl https://<your-service>.onrender.com/                            # {"status":"ok"}
curl -X POST https://<your-service>.onrender.com/v1/chat/completions \
  -H "Authorization: Bearer <API_KEY>" -H "Content-Type: application/json" \
  -d '{"model":"gemini-3.6-flash","messages":[{"role":"user","content":"hi"}]}'
```

管理面板:`https://<your-service>.onrender.com/admin`(用 `ADMIN_TOKEN` 登录,可在线改代理池 / 设置 / API key)。

## 说明

- Render 免费层空闲约 30 秒后休眠,首次请求需几十秒冷启动;数据落挂载磁盘 `/data`,但免费磁盘可能非持久,适合试玩。
- `API_KEY` 为空时,gemini 首次启动会自生成一把 key 存 SQLite,可在面板轮换。