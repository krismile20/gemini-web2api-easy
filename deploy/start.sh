#!/bin/sh
set -e

export EASY_SUB_URL="${EASY_SUB_URL:-}"

if [ -z "$EASY_SUB_URL" ]; then
  echo "[start.sh] WARNING: EASY_SUB_URL is empty, easy_proxies will have no subscription." >&2
fi

# Substitute subscription URL into easy_proxies config (env-injected at boot).
sed "s|__SUB_URL__|$EASY_SUB_URL|g" /etc/easy_proxies/config-easy.yaml > /etc/easy_proxies/config.yaml

# Start easy_proxies in the background as the upstream proxy pool gateway.
echo "[start.sh] starting easy_proxies (pool on 127.0.0.1:2323)"
/app/easy_proxies --config /etc/easy_proxies/config.yaml &
EASY_PID=$!

# Small wait so easy_proxies can bind its listener before gemini dials it.
sleep 1

# Start gemini-web2api-go as the foreground process (the Render-exposed API).
# --api-key and --admin-token come from env; empty api-key falls back to the
# auto-generated key stored in the DB (mutable from the /admin UI).
echo "[start.sh] starting gemini-web2api-go (0.0.0.0:8083 via proxy -> 127.0.0.1:2323)"
exec /app/gemini-web2api-go \
  --port 8083 \
  --proxy http://127.0.0.1:2323 \
  --admin-token "$ADMIN_TOKEN" \
  --api-key "$API_KEY" \
  --db /data/gemini.db