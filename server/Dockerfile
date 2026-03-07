FROM node:20-alpine AS builder

WORKDIR /app

# Copy workspace config
COPY package.json ./
COPY tsconfig.base.json ./

# Copy shared
COPY shared/package.json shared/
COPY shared/tsconfig.json shared/
COPY shared/src shared/src

# Copy server
COPY server/package.json server/
COPY server/tsconfig.json server/
COPY server/nest-cli.json server/
COPY server/src server/src

# Install & build
RUN npm install --workspace=shared --workspace=server
RUN npm run build --workspace=shared
RUN npm run build --workspace=server

# ─── Production ───────────────────────────────────────────────

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/package.json ./
COPY --from=builder /app/shared/package.json shared/
COPY --from=builder /app/shared/dist shared/dist
COPY --from=builder /app/server/package.json server/
COPY --from=builder /app/server/dist server/dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/shared/node_modules shared/node_modules
COPY --from=builder /app/server/node_modules server/node_modules

WORKDIR /app/server
CMD ["node", "dist/main.js"]
EXPOSE 3000

