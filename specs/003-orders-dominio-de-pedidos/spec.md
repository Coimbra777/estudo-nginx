# F03 — Orders Service: Domínio de Pedidos

**Provê:** `pedido confirmado` vinculado a um usuário validado e a reservas de
estoque efetivadas.
**Consome:** `usuário persistido` (F01, via `GET /users/:id/exists`) ·
`convenção de borda` (F02, correlation-id) · `disponibilidade reservável` (F07,
reserva/confirmação/liberação de estoque).

## Contexto

`projeto-nest-1/src` hoje só tem o `AppController`/`AppService` padrão gerado
pelo Nest CLI — `getHello()` retorna a string `'Orders Service is running!'`.
Não existe `OrdersModule`, entidade ou controller, mesmo o Nginx já expondo
`/api/orders/` apontando para este container (`docker/nginx/default.conf`).

**Atualização desta feature (revisão 2 do PRD):** o domínio do produto agora é
uma loja de ingressos e produtos (ver `PRD.md`, seção 1). Isso muda o que
`Orders` orquestra: já não é um pedido genérico com preço informado à mão — cada
linha do pedido corresponde a um item real do catálogo (F07), com estoque
controlado atomicamente. `Orders` deixa de ser só "persistir um pedido" e passa
a orquestrar uma pequena saga: validar comprador → reservar estoque → confirmar
ou liberar.

## Objetivo

Criar o domínio de pedidos com persistência própria (mesmo padrão
*database-per-service* de F01/F07), validando o comprador via Users Service e o
estoque via Catalog Service — o primeiro caso do projeto com dois serviços
consumidos numa única operação de escrita, e o motivo pelo qual esta feature só
entra na wave 2 (depende de F01, F02 e F07 existirem de verdade).

## Fluxo (saga simples: reservar → confirmar/liberar)

1. `POST /orders { userId, items: [{ catalogItemId, quantity }] }`.
2. Valida `userId` via `GET /users/:id/exists` (F01) — se `false`, `422`, nada é
   criado.
3. Para cada item, chama `POST /catalog/items/:id/reservations` (F07). Se
   qualquer reserva falhar (`409`, estoque insuficiente), libera as reservas já
   feitas nesta chamada (compensação) e retorna `409` sem criar o pedido.
4. Se todas as reservas foram feitas, persiste `Order` com
   `status: "pending_payment"` e a lista de `reservationIds`.
5. `POST /orders/:id/confirm` — simula o pagamento aprovado: chama
   `POST /catalog/reservations/:id/confirm` (F07) para cada reserva e marca o
   pedido `confirmed`. Um gateway de pagamento real está fora de escopo (`PRD.md`,
   seção 4) — este passo existe só para fechar o fluxo de ponta a ponta.
6. `POST /orders/:id/cancel` — libera as reservas (`.../release`, F07) e marca o
   pedido `cancelled`.

## Modelo de dados

```
Order {
  id: uuid
  userId: uuid              // validado contra users_service, nunca confiado sem checagem
  items: [{ catalogItemId: uuid, quantity: number, reservationId: uuid }]
  status: "pending_payment" | "confirmed" | "cancelled"
  createdAt: timestamp
}
```

## Escopo

- `orders_db` (Postgres dedicado, mesmo padrão de F01/F07) — `orders_service`
  nunca lê o banco de `users_service`, `catalog_service` nem do Laravel.
- `OrdersModule` com `OrdersController`: `POST /orders`, `GET /orders`,
  `GET /orders/:id`, `POST /orders/:id/confirm`, `POST /orders/:id/cancel`.
- `UsersClient` — encapsula `GET http://users_service:3001/users/:id/exists`,
  lendo a URL base de env (`USERS_SERVICE_URL`), nunca hardcoded.
- `CatalogClient` — encapsula as três chamadas de F07 (`reservations`,
  `.../confirm`, `.../release`), lendo `CATALOG_SERVICE_URL` de env.
- Repassar o `X-Correlation-Id` recebido do gateway em todas as chamadas
  downstream (Users e Catalog).

## Fora de escopo

- Comunicação assíncrona (evento em vez de chamada HTTP síncrona a Users e
  Catalog) — evolução natural depois que o acoplamento síncrono incomodar; não
  faz parte desta rodada.
- Gateway de pagamento real — `confirm`/`cancel` simulam o resultado do
  pagamento, não integram um provedor de verdade.
- Preço calculado a partir do catálogo no momento do pedido (ex.: `totalAmount`)
  — pode ser adicionado numa iteração futura; esta feature foca no fluxo de
  reserva/confirmação, não no cálculo financeiro.

## Critérios de aceitação

- [ ] `POST /orders` com `userId` inexistente retorna `422` e não persiste nada
      nem reserva estoque.
- [ ] `POST /orders` com estoque insuficiente em qualquer item retorna `409`,
      libera as reservas já feitas na mesma chamada, e não persiste o pedido.
- [ ] `POST /orders` bem-sucedido retorna `201` com `status: "pending_payment"`.
- [ ] `POST /orders/:id/confirm` chama `confirm` em cada reserva de F07 e muda o
      pedido para `confirmed`.
- [ ] `POST /orders/:id/cancel` chama `release` em cada reserva de F07 e muda o
      pedido para `cancelled`.
- [ ] O log de `users_service`, `catalog_service` e `orders_service` para a
      mesma criação de pedido compartilham o mesmo `X-Correlation-Id` (valida
      também F02/F04 na prática).
- [ ] `docker compose restart orders_service` não apaga pedidos já criados.
