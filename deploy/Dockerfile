# syntax=docker/dockerfile:1

# =============================================================================
# Stage 1: build easy_proxies (multi-arch, static via project's proven tags)
# =============================================================================
FROM --platform=$BUILDPLATFORM golang:1.24 AS easy-builder
ARG TARGETARCH
ARG GOPROXY=https://proxy.golang.org,direct
WORKDIR /src
# Clone the pinned-upstream easy_proxies source fresh (self-contained build).
RUN git clone --depth 1 https://github.com/jasonwong1991/easy_proxies.git .
RUN go env -w GOPROXY=${GOPROXY} && go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} \
    go build -tags "with_utls with_quic with_grpc with_wireguard with_gvisor with_clash_api" \
    -o /out/easy_proxies ./cmd/easy_proxies

# =============================================================================
# Stage 2: build gemini-web2api-go (self-contained, no external clone)
# =============================================================================
FROM golang:1.26 AS gemini-builder
ARG TARGETARCH
WORKDIR /g
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /out/gemini-web2api-go .

# =============================================================================
# Stage 3: runtime
# =============================================================================
FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates timezone curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /app /etc/easy_proxies /data

COPY --from=easy-builder   /out/easy_proxies       /app/easy_proxies
COPY --from=gemini-builder /out/gemini-web2api-go  /app/gemini-web2api-go
RUN chmod +x /app/easy_proxies /app/gemini-web2api-go

COPY deploy/config-easy.yaml /etc/easy_proxies/config-easy.yaml
COPY deploy/start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV EASY_SUB_URL=""
ENV ADMIN_TOKEN=""
ENV API_KEY=""

EXPOSE 8083

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8083/ >/dev/null || exit 1

CMD ["/app/start.sh"]