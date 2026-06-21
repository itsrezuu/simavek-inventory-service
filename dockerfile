FROM hasura/graphql-engine:v2.36.0

LABEL maintainer="SIMAVEK Team"
LABEL service="inventory-service"
LABEL description="Inventory Service - Hasura GraphQL Engine"
LABEL version="1.0.0"

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

ENV HASURA_GRAPHQL_ENABLE_CONSOLE=true
ENV HASURA_GRAPHQL_CORS_DOMAIN="*"
ENV HASURA_GRAPHQL_DEV_MODE=true
ENV HASURA_GRAPHQL_ENABLE_TELEMETRY=false

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1

EXPOSE 8080

CMD ["graphql-engine", "serve"]