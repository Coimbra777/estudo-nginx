# F08 — Contrato

## Provê

`experiência de compra` — não é uma API consumida por outro serviço (é a ponta
voltada ao comprador), então não tem um "provê" no sentido de endpoint
reutilizável. O contrato relevante aqui é o inverso: o que ela promete ao
comprador.

- `GET /catalog` → página com itens disponíveis (dados de F07, ao vivo).
- `POST /checkout` → `pedido confirmado` (sucesso, repassando F03) ou mensagem
  de estoque esgotado/comprador inválido (repassando os erros de F07/F01/F03).

## Consome

- **F07 — `GET /catalog/items`** para montar a vitrine.
- **F03 — `POST /orders`** para efetivar a compra.
- **F01 — `GET /users/:id/exists`** para validar o comprador antes de tentar o
  checkout (evita depender só do erro que F03 já retornaria).

## Consumido por

**F10 (Teste de carga)** pode optar por bater direto no gateway
(`/api/orders/`) ou passar pela storefront — ver `specs/010-.../spec.md` para
qual caminho o cenário de carga usa.
