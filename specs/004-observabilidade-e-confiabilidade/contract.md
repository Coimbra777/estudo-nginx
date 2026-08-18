# F04 — Contrato

## Provê

- `GET /health` → `200 { status: "ok" }` em `users_service`, `orders_service` e
  `laravel`. Rota de uso interno/compose — **não** roteada pelo gateway em
  `/api/*` (não faz sentido expor healthcheck de serviço interno publicamente).
- Toda linha de log dos serviços Node inclui `correlationId` quando o header
  `X-Correlation-Id` está presente na requisição.

## Consome

- **F02 — header `X-Correlation-Id`** — usado para enriquecer o log; se ausente
  (chamada direta ao serviço, bypassando o gateway), o log simplesmente não tem
  `correlationId`, sem erro.

## Consumido por

Nenhuma feature depende diretamente de F04 no código — é infraestrutura de
confiabilidade/observação consumida por quem opera o ambiente (você), não por
outro serviço.
