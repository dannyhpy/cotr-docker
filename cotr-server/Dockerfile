FROM docker.io/nimlang/nim:1.6.10 AS nim-builder

WORKDIR /root/src

# Dependencies
COPY ./cotr.nimble .
RUN \
  --mount=type=cache,target=/root/.cache/nim \
  --mount=type=cache,target=/root/.nimble \
  nimble install -d -y

# Copy sources
COPY ./src ./src
RUN \
  --mount=type=cache,target=/root/.cache/nim \
  --mount=type=cache,target=/root/.nimble \
  nimble build -d:ssl -d:dbPostgres -d:awaitDbPostgres -d:noProxy


FROM docker.io/library/debian:stable-20230109-slim

# System dependencies
RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && \
  apt-get install -y \
    ca-certificates \
    libpq-dev \
    openssl \
    sqlite3

COPY --from=nim-builder /root/src/bin/cotr /bin
CMD ["/bin/cotr"]
