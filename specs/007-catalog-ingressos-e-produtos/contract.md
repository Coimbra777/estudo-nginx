# F07 — Contrato

## Provê

| Rota | Resposta |
|---|---|
| `GET /catalog/items` | `200 [{ id, type, name, price, availableNow }]` |
| `GET /catalog/items/:id` | `200 { ...item }` \| `404` |
| `POST /catalog/items` | `201 { ...item }` |
| `POST /catalog/items/:id/reservations` | `201 { reservationId, expiresAt }` \| `409 { message: "insufficient_stock" }` |
| `POST /catalog/reservations/:id/confirm` | `200 { confirmed: true }` \| `410 { message: "reservation expired" }` |
| `POST /catalog/reservations/:id/release` | `200 { released: true }` |

Formato de erro padrão: `{ statusCode, message }` (mesmo padrão de F01/F03).

Roteado externamente via gateway em `/api/catalog/*` — leitura sem limite
especial, escrita de reservas sob rate limiting de F09.

## Consome

Nada.

## Consumido por

- **F03 (Orders)** — reserva um item por linha do pedido antes de confirmar;
  confirma ou libera de acordo com o resultado do pagamento simulado.
- **F08 (Storefront)** — lê `GET /catalog/items` para montar a vitrine.
- **F10 (Teste de carga)** — dispara reservas concorrentes contra o mesmo item
  para validar o critério de aceitação central desta feature.

## Garantia de contrato

Sob qualquer volume de chamadas concorrentes a
`POST /catalog/items/:id/reservations` para o mesmo `:id`, a soma das reservas
com status `pending` ou `confirmed` nunca excede `quantityTotal`. Essa garantia é
o motivo de existir desta feature — se um consumidor encontrar um jeito de
furá-la, é bug de F07, não do consumidor.
