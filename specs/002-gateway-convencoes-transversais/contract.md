# F02 — Contrato

## Provê

- Header `X-Correlation-Id` presente em:
  - toda resposta do gateway ao cliente;
  - toda requisição repassada a `users_service`, `orders_service` e `laravel`.
- Formato de erro de upstream indisponível: `502/504 { "error": string }` (JSON,
  nunca HTML) em qualquer rota atrás de `proxy_pass`.
- Timeout de upstream: conexão falha após 3s, leitura falha após 10s (valores
  configuráveis em `default.conf`, não um contrato numérico rígido).

## Consome

Nada.

## Consumido por

- **F03 (Orders Service)** — deve ler `X-Correlation-Id` da requisição recebida e
  repassá-lo na chamada HTTP a `users_service`.
- **F04 (Observabilidade)** — os loggers estruturados dos serviços leem este header
  para correlacionar logs entre `users_service` e `orders_service` numa mesma
  requisição.
- **F06 (Auth entre gateway e serviços)** — reaproveita o mesmo ponto de injeção de
  headers (`proxy_set_header`) para adicionar `X-Internal-Token`.
