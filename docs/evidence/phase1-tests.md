# Phase 1 Isolation & Persistence Tests

## Test 1: The app loads by name
```bash
curl -i -s http://shoplite.test
HTTP/1.1 200 OK
Server: nginx/1.29.8
Date: Tue, 24 Nov 2026 20:23:30 GMT
Content-Type: text/html
Content-Length: 393
Last-Modified: Tue, 24 Nov 2026 19:46:00 GMT
Connection: keep-alive
ETag: "6b05e978-189"
Accept-Ranges: bytes

<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ShopLite</title>
    <script type="module" crossorigin src="/assets/index-CVx7uJlY.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-DjmoLBf1.css">
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
```

## Test 2: APIs work through nginx
```bash
curl -s http://shoplite.test/api/catalog/products
[{"id":1,"name":"Keyboard","price":4500},{"id":2,"name":"Mouse","price":1800},{"id":3,"name":"Monitor","price":32000}]
```

## Test 3: An order works end to end
```bash
curl -i -s -X POST http://shoplite.test/api/orders/orders -H 'Content-Type: application/json' -d '{"productId":1,"quantity":2}'
HTTP/1.1 201 
Server: nginx/1.29.8
Date: Tue, 24 Nov 2026 20:23:31 GMT
Content-Type: application/json
Transfer-Encoding: chunked
Connection: keep-alive

{"id":1,"productId":1,"quantity":2,"total":9000.00,"createdAt":"2026-11-24T20:23:31.816545"}
curl -s http://shoplite.test/api/inventory/stock/1
{"productId":1,"quantity":18}

```

## Test 4: Backends aren't published
```bash
--- curl http://localhost:3000 ---
--- curl http://localhost:8081 ---
--- curl http://localhost:8082 ---
--- docker ps --format '{{.Names}} {{.Ports}}' ---
frontend 0.0.0.0:80->80/tcp, [::]:80->80/tcp, 8080/tcp
orders 8082/tcp
inventory 8081/tcp
catalog 3000/tcp
postgres 5432/tcp
```

## Test 5: The frontend network can't see Postgres
```bash
docker run --rm --network frontend-net busybox wget -T 3 -qO- http://postgres:5432
wget: bad address 'postgres:5432'
```

## Test 6: Backends reach each other on backend-net
```bash
docker run --rm --network backend-net busybox wget -T 3 -qO- http://catalog:3000/health
{"status":"ok"}
```

## Test 7: Postgres has no internet
```bash
docker exec postgres wget -T 5 -qO- https://example.com
wget: bad address 'example.com'
```

## Test 8: Data survives a restart
```bash
./scripts/down.sh && TAG=1.0.0 ./scripts/up.sh && curl -s http://shoplite.test/api/orders/orders
Removed containers and networks (kept pgdata volume).
postgres is healthy.
catalog is healthy.
inventory is healthy.
orders is healthy.
frontend is healthy.
ShopLite stack is up (TAG=1.0.0).
[{"id":1,"productId":1,"quantity":2,"total":9000.00,"createdAt":"2026-11-24T20:23:31.816545"}]
```

## Test 9: Only --purge deletes data
```bash
./scripts/down.sh --purge && TAG=1.0.0 ./scripts/up.sh && curl -s http://shoplite.test/api/orders/orders && curl -s http://shoplite.test/api/inventory/stock/1
Removed containers, networks, and pgdata volume.
postgres is healthy.
catalog is healthy.
inventory is healthy.
orders is healthy.
frontend is healthy.
ShopLite stack is up (TAG=1.0.0).
[]
{"productId":1,"quantity":20}

```

## Test 10: Only the domain is served
```bash
curl -v http://127.0.0.1
  % Total    % Received % Xferd  Average Speed  Time    Time    Time   Current
                                 Dload  Upload  Total   Spent   Left   Speed
  0      0   0      0   0      0      0      0                              0*   Trying 127.0.0.1:80...
* Established connection to 127.0.0.1 (127.0.0.1 port 80) from 127.0.0.1 port 55614 
* using HTTP/1.x
> GET / HTTP/1.1
> Host: 127.0.0.1
> User-Agent: curl/8.18.0
> Accept: */*
> 
* Request completely sent off
  0      0   0      0   0      0      0      0                              0  0      0   0      0   0      0      0      0                              0* Empty reply from server
  0      0   0      0   0      0      0      0                              0
* shutting down connection #0
curl: (52) Empty reply from server
curl -v -H 'Host: other.test' http://127.0.0.1
  % Total    % Received % Xferd  Average Speed  Time    Time    Time   Current
                                 Dload  Upload  Total   Spent   Left   Speed
  0      0   0      0   0      0      0      0                              0*   Trying 127.0.0.1:80...
* Established connection to 127.0.0.1 (127.0.0.1 port 80) from 127.0.0.1 port 55620 
* using HTTP/1.x
> GET / HTTP/1.1
> Host: other.test
> User-Agent: curl/8.18.0
> Accept: */*
> 
* Request completely sent off
  0      0   0      0   0      0      0      0                              0  0      0   0      0   0      0      0      0                              0* Empty reply from server
  0      0   0      0   0      0      0      0                              0
* shutting down connection #0
curl: (52) Empty reply from server
```
## Docker Networks & Images
```bash
docker network inspect frontend-net backend-net --format '{{.Name}}: {{range .Containers}}{{.Name}} {{end}}'
frontend-net: orders inventory catalog frontend 
backend-net: postgres orders inventory catalog 
--- docker images ---
REPOSITORY          TAG         SIZE
shop-frontend       1.0.0       20.9MB
shop-orders         1.0.0       159MB
shop-catalog        1.0.0       190MB
shop-inventory      1.0.0       21.3MB
postgres            17-alpine   424MB
busybox             latest      6.81MB
hello-world         latest      25.9kB
hadolint/hadolint   v2.12.0     4.82MB
```
## Docker Networks & Images
```bash
docker network inspect frontend-net backend-net --format '{{.Name}}: {{range .Containers}}{{.Name}} {{end}}'
frontend-net: orders inventory catalog frontend 
backend-net: postgres orders inventory catalog 
--- docker images ---
REPOSITORY          TAG         SIZE
shop-frontend       1.0.0       20.9MB
shop-orders         1.0.0       159MB
shop-catalog        1.0.0       190MB
shop-inventory      1.0.0       21.3MB
postgres            17-alpine   424MB
busybox             latest      6.81MB
hello-world         latest      25.9kB
hadolint/hadolint   v2.12.0     4.82MB
```
