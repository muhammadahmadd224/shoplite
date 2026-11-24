# ---- Stage 1: build ----
FROM golang:1.26-alpine AS build
WORKDIR /src

# Copy dependency files first so Docker caches the download step
COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/inventory-service .

# ---- Stage 2: tiny final image ----
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/inventory-service /inventory-service

USER nonroot:nonroot
EXPOSE 8081

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/inventory-service", "-healthcheck"]

ENTRYPOINT ["/inventory-service"]
