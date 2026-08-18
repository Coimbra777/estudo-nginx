# F07 — Catalog Service: Ingressos e Produtos

**Provê:** `disponibilidade reservável` — catálogo de ingressos e produtos com
controle de estoque atômico (reservar, confirmar, liberar), resistente a
concorrência alta.
**Consome:** nada (feature-base, wave 1).

## Contexto

Esta feature não existia na primeira revisão do PRD — nasce do case definido:
loja de ingressos (estoque por evento, tipicamente pequeno e disputado) e
produtos (estoque convencional). Não existe hoje nenhum serviço, pasta ou
container para isso; é criada do zero, seguindo o mesmo padrão
*database-per-service* de F01/F03.

## Objetivo

Ser o único dono da resposta a "quanto ainda tem disponível" e garantir que, sob
qualquer volume de requisições concorrentes, o serviço nunca reserve mais do que
existe — esse é o requisito que motiva o case inteiro (ver `PRD.md`, seção 5).

## Modelo de dados

```
CatalogItem {
  id: uuid
  type: "ticket" | "product"
  name: string
  price: decimal
  quantityTotal: number
  attributes: jsonb   // ticket: { eventDate, venue } · product: { sku }
}

Reservation {
  id: uuid
  catalogItemId: uuid
  quantity: number
  status: "pending" | "confirmed" | "released" | "expired"
  expiresAt: timestamp
  createdAt: timestamp
}
```

`quantityTotal` fica no Postgres (fonte de verdade duradoura, usada para
auditoria/relatório). A quantidade **disponível agora** vive no Redis, como um
contador (`catalog:available:<itemId>`) inicializado a partir de `quantityTotal`
na criação do item — é o Redis, não o Postgres, que responde "dá pra vender mais
um?" no caminho quente.

## Escopo

- `catalog_db` (Postgres dedicado) + o `redis` já ativado por F05, reaproveitado
  aqui para os contadores de estoque (com prefixo de chave `catalog:` para não
  colidir com o cache do Laravel).
- Reserva atômica via script Lua no Redis (`EVAL`): checa `available >= quantity`
  e decrementa numa única operação — elimina a corrida clássica de
  "ler-depois-escrever" que causa overselling sob concorrência.
- Reserva tem TTL (ex.: 5 min); se ninguém confirmar, expira e devolve a
  quantidade ao contador (verificação preguiçosa, ver "fora de escopo").
- Endpoints:
  - `GET /catalog/items` · `GET /catalog/items/:id`
  - `POST /catalog/items` (seed/admin — cria ingresso ou produto)
  - `POST /catalog/items/:id/reservations` `{ quantity }` → reserva atômica
  - `POST /catalog/reservations/:id/confirm` → torna a reserva definitiva,
    decrementa `quantityTotal` no Postgres (durável, para relatório/auditoria)
  - `POST /catalog/reservations/:id/release` → devolve a quantidade ao contador

## Fora de escopo

- Overselling via fila de espera visual — F09 cobre rate limiting, não uma UI de
  fila.
- Precificação dinâmica, cupom de desconto — `price` é fixo por item.
- Worker de expiração dedicado — nesta rodada a expiração é verificada de forma
  preguiçosa (ao tentar confirmar/reservar, checa se `expiresAt` já passou); um
  worker de limpeza fica como sugestão de evolução futura.

## Critérios de aceitação

- [ ] N requisições concorrentes de reserva contra um item com `quantityTotal=1`
      resultam em exatamente 1 sucesso e N-1 respostas `409`.
- [ ] `POST /catalog/reservations/:id/confirm` depois do TTL expirado retorna
      `410 { message: "reservation expired" }` e não decrementa o Postgres.
- [ ] `POST /catalog/reservations/:id/release` devolve a quantidade ao contador
      do Redis, verificável por uma nova reserva bem-sucedida logo em seguida.
- [ ] `docker compose restart catalog_service` não perde o `quantityTotal`
      cadastrado (fonte durável é o Postgres); o contador do Redis é
      re-hidratado a partir do Postgres na inicialização.
