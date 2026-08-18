# F03 — Contrato

## Provê

| Rota | Resposta |
|---|---|
| `POST /orders` | `201 { id, userId, items, status: "pending", createdAt }` \| `422 { statusCode: 422, message: "user not found" }` |
| `GET /orders` | `200 [{ ...order }]` |
| `GET /orders/:id` | `200 { ...order }` \| `404 { statusCode: 404, message: "Order not found" }` |
| `PATCH /orders/:id/status` | `200 { ...order atualizado }` — corpo: `{ status: "confirmed" \| "cancelled" }` |

Formato de erro padrão: `{ statusCode, message }` (mesmo padrão de F01, para o
gateway/cliente não precisar tratar dois formatos diferentes).

Roteado externamente via gateway em `/api/orders/*` (prefixo removido pelo Nginx,
ver F02).

## Consome

- **F01 — `GET /users/:id/exists`** → `{ exists: boolean }`. Se F01 mudar o formato
  desta resposta, esta feature quebra silenciosamente — qualquer alteração no
  contrato de F01 exige revisar este arquivo.
- **F02 — header `X-Correlation-Id`** — lido da requisição recebida do gateway e
  repassado na chamada a `users_service`, não gerado localmente.

## Trade-off assumido

A validação de `userId` é síncrona (chamada HTTP bloqueante no momento do
`POST /orders`). Se `users_service` estiver indisponível, `orders_service` também
fica incapaz de criar pedidos — comportamento aceito conscientemente nesta fase; a
alternativa (validação assíncrona via evento) é sugestão de evolução futura, não
parte deste contrato.
