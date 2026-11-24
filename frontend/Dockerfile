# ---- Stage 1: build the React app into static files ----
FROM node:26-alpine AS build
WORKDIR /app

# Dependency files first so the npm install step is cached
COPY package.json package-lock.json ./
RUN npm ci

COPY index.html vite.config.js ./
COPY src ./src
RUN npm run build

# ---- Stage 2: nginx serves the files (runs as non-root) ----
FROM nginxinc/nginx-unprivileged:1.29-alpine-slim

# Default so the image starts even if the variable is missing
ENV SERVER_NAME=shoplite.test

# Files in /etc/nginx/templates are run through envsubst at container start
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null --header="Host: ${SERVER_NAME}" http://127.0.0.1/health || exit 1
