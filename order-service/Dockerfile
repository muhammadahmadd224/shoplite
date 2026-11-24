# ---- Stage 1: build the jar ----
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /build

# Dependency file first so the download step is cached
COPY pom.xml ./
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q package -DskipTests

# ---- Stage 2: build a trimmed Java runtime with only the needed modules ----
FROM eclipse-temurin:21-jdk-alpine AS jre
RUN jlink \
    --add-modules java.base,java.logging,java.naming,java.sql,java.xml,java.desktop,java.management,java.instrument,java.security.jgss,java.net.http,jdk.unsupported,jdk.crypto.ec \
    --strip-debug --no-man-pages --no-header-files --compress=zip-6 \
    --output /custom-jre

# ---- Stage 3: small final image ----
FROM alpine:3.22
RUN addgroup -S app && adduser -S app -G app

ENV JAVA_HOME=/opt/java
ENV PATH="${JAVA_HOME}/bin:${PATH}"
COPY --from=jre /custom-jre ${JAVA_HOME}

WORKDIR /app
COPY --from=build /build/target/order-service.jar ./order-service.jar

ENV SERVER_PORT=8082
USER app
EXPOSE 8082

HEALTHCHECK --interval=10s --timeout=3s --start-period=40s --retries=3 \
  CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8082/health"]

ENTRYPOINT ["java", "-jar", "/app/order-service.jar"]
