# F09 — Contrato

## Provê

- `429 { "error": "rate limit exceeded" }` em `POST /api/orders/` e
  `POST /api/catalog/*/reservations` quando a taxa configurada é excedida.
- Nenhuma mudança de contrato nas rotas que não são limitadas
  (`GET /api/catalog/items`, `GET /api/orders/:id`, etc.).

## Consome

- **F02** — reaproveita o formato de erro JSON já padronizado para upstream
  indisponível, aplicado agora também ao `429`.

## Consumido por

- **F10 (Teste de carga)** — o cenário de pico deve esperar (e validar) uma
  fatia de respostas `429` sob carga alta, não tratar isso como falha do
  sistema.
