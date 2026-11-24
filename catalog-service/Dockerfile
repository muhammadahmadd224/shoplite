# ---- Stage 1: install production dependencies and slim down node ----
FROM node:26-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
# hadolint ignore=DL3018
RUN apk add --no-cache binutils \
    && strip --strip-all /usr/local/bin/node

# ---- Stage 2: small runtime image ----
FROM alpine:3.22
# Node on Alpine needs the C++ runtime library
# hadolint ignore=DL3018
RUN apk add --no-cache libstdc++ libatomic \
    && addgroup -S app && adduser -S app -G app

COPY --from=deps /usr/local/bin/node /usr/local/bin/node

ENV NODE_ENV=production
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY src ./src

USER app
EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
  CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:3000/health"]

CMD ["node", "src/index.js"]
