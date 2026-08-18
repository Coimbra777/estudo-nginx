# F03 — Contrato

## Provê

| Rota | Resposta |
|---|---|
| `POST /orders` | `201 { id, userId, items, status: "pending_payment", createdAt }` \| `422 { message: "user not found" }` \| `409 { message: "insufficient_stock" }` |
| `GET /orders` | `200 [{ ...order }]` |
| `GET /orders/:id` | `200 { ...order }` \| `404 { message: "Order not found" }` |
| `POST /orders/:id/confirm` | `200 { ...order, status: "confirmed" }` |
| `POST /orders/:id/cancel` | `200 { ...order, status: "cancelled" }` |

Formato de erro padrão: `{ statusCode, message }` (mesmo padrão de F01/F07, para
o gateway/cliente não precisar tratar formatos diferentes).

Roteado externamente via gateway em `/api/orders/*` (prefixo removido pelo
Nginx, ver F02); `POST /orders` sob rate limiting de F09.

## Consome

- **F01 — `GET /users/:id/exists`** → `{ exists: boolean }`. Mudança no formato
  desta resposta quebra esta feature silenciosamente.
- **F07 — `POST /catalog/items/:id/reservations`**,
  `POST /catalog/reservations/:id/confirm`,
  `POST /catalog/reservations/:id/release` — os três precisam se comportar
  exatamente como documentado em `specs/007-.../contract.md`; em particular, o
  `409` de estoque insuficiente é o sinal que aciona a compensação (passo 3 do
  fluxo em `spec.md`).
- **F02 — header `X-Correlation-Id`** — lido da requisição recebida do gateway
  e repassado em toda chamada a `users_service` e `catalog_service`, nunca
  gerado localmente.

## Trade-off assumido

A validação de comprador e a reserva de estoque são síncronas (chamadas HTTP
bloqueantes dentro de `POST /orders`). Se `users_service` ou `catalog_service`
estiverem indisponíveis, `orders_service` também fica incapaz de criar
pedidos — comportamento aceito conscientemente nesta fase; a alternativa
(orquestração assíncrona via evento) é sugestão de evolução futura, não parte
deste contrato.
