# F04 — Observabilidade e Confiabilidade do Compose

**Provê:** `ambiente observável` — healthchecks, startup ordenado, logs
correlacionáveis entre serviços.
**Consome:** `convenção de borda` (F02, correlation-id para enriquecer log).

## Contexto

Nenhum serviço do `docker-compose.yml` tem `healthcheck`; `depends_on` só espera o
container **iniciar**, não ficar **pronto** — o `nginx` pode subir e começar a
rotear antes do PHP-FPM ou dos serviços Node aceitarem conexão, gerando 502
esporádico nos primeiros segundos após `docker compose up`. Logs de cada serviço
não têm formato padronizado nem qualquer id que permita correlacionar uma
requisição entre `users_service` e `orders_service`.

## Objetivo

Cada serviço expõe `GET /health`; o compose usa `healthcheck` +
`condition: service_healthy`; e os serviços Node logam em JSON incluindo o
`X-Correlation-Id` recebido do gateway.

## Escopo

- `GET /health` em `users_service`, `orders_service` e `catalog_service` (F07)
  via `@nestjs/terminus` (liveness simples — não depende do banco, para não
  confundir "serviço fora do ar" com "banco fora do ar").
- `GET /health` leve no Laravel/storefront (`routes/web.php`, sem tocar
  banco/redis).
- Bloco `healthcheck:` no `docker-compose.yml` para `users_service`,
  `orders_service`, `catalog_service`, `laravel`, `mysql-laravel`, `redis`, e os
  bancos dedicados (`users_db`, `orders_db`, `catalog_db`).
- `nginx`/`gateway` passa a usar `depends_on` na forma longa com
  `condition: service_healthy` para os serviços que ele roteia.
- Interceptor/logger estruturado nos três serviços Node, extraindo
  `X-Correlation-Id` do header e incluindo como campo `correlationId` em cada linha
  de log.

## Fora de escopo

- Stack de observabilidade externa (Grafana/Loki/Prometheus) — fica como sugestão
  de evolução futura; esta feature só arruma a base (healthcheck + log
  estruturado), não introduz infraestrutura nova de monitoramento.

## Critérios de aceitação

- [ ] `docker compose ps` mostra `healthy` para todos os serviços com healthcheck
      definido, dentro de ~30s após `up`.
- [ ] Nginx não retorna 502 nos primeiros segundos após `docker compose up`
      (comportamento hoje possível, por rotear antes do PHP-FPM/Node estarem
      prontos).
- [ ] Uma linha de log de `users_service` e uma de `orders_service` para a mesma
      requisição de criação de pedido (F03) têm o mesmo `correlationId`.
