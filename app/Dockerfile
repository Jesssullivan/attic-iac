FROM node:22-alpine AS builder
WORKDIR /workspace
RUN corepack enable pnpm

# Workspace root files (lockfile, workspace config)
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml .npmrc ./
COPY app/package.json app/

RUN pnpm install --frozen-lockfile

# App source + config for prebuild
COPY app/ app/
COPY config/ config/

WORKDIR /workspace/app
RUN pnpm build
RUN pnpm prune --prod

# --- Production ---
FROM node:22-alpine
WORKDIR /app
RUN apk add --no-cache ca-certificates

COPY --from=builder /workspace/app/build build/
COPY --from=builder /workspace/app/node_modules node_modules/
COPY --from=builder /workspace/app/package.json .

ENV NODE_ENV=production PORT=3000
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/health || exit 1
USER node
CMD ["node", "build/index.js"]
