# F03 — Orders Service: Domínio de Pedidos

**Provê:** `pedido persistido` vinculado a um usuário validado.
**Consome:** `usuário persistido` (F01, via `GET /users/:id/exists`) ·
`convenção de borda` (F02, correlation-id).

## Contexto

`projeto-nest-1/src` hoje só tem o `AppController`/`AppService` padrão gerado pelo
Nest CLI — `getHello()` retorna a string `'Orders Service is running!'`. Não existe
`OrdersModule`, entidade ou controller, mesmo o Nginx já expondo
`/api/orders/` apontando para este container (`docker/nginx/default.conf`).

## Objetivo

Criar o domínio de pedidos do zero, com persistência própria (mesmo padrão
*database-per-service* de F01), e validar o `userId` chamando o Users Service via
HTTP — o primeiro caso real de comunicação serviço-a-serviço do projeto, e o
motivo pelo qual esta feature só entra na wave 2 (depende de F01 existir e F02
padronizar como o correlation-id é propagado).

## Modelo de dados mínimo

```
Order {
  id: uuid
  userId: uuid        // validado contra users_service, nunca confiado sem checagem
  items: [{ productName: string, quantity: number, unitPrice: number }]
  status: "pending" | "confirmed" | "cancelled"
  createdAt: timestamp
}
```

## Escopo

- `orders_db` (Postgres dedicado, mesmo padrão de F01) — `orders_service` nunca lê
  o banco de `users_service` nem o do Laravel.
- `OrdersModule` com `OrdersController`: `POST /orders`, `GET /orders`,
  `GET /orders/:id`, `PATCH /orders/:id/status`.
- `UsersClient` — provider injetável que encapsula a chamada
  `GET http://users_service:3001/users/:id/exists`, lendo a URL base de uma env
  (`USERS_SERVICE_URL`), nunca hardcoded.
- Repassar o `X-Correlation-Id` recebido do gateway na chamada a `users_service`.
- `items` pode ser persistido como coluna JSON (não precisa de tabela própria) —
  suficiente para o escopo de estudo.

## Fora de escopo

- Comunicação assíncrona (evento `user.created` cacheado localmente em
  `orders_service` para evitar a chamada síncrona) — é a evolução natural depois
  que o acoplamento síncrono descrito abaixo incomodar; não faz parte desta rodada.
- Cálculo de preço/estoque real — `unitPrice` é informado no `POST`, não calculado.

## Critérios de aceitação

- [ ] `POST /api/orders/` com `userId` inexistente retorna `422` e não persiste
      nada.
- [ ] `POST /api/orders/` com `userId` válido retorna `201` com o pedido criado.
- [ ] O log de `users_service` (chamada a `/users/:id/exists`) e o log de
      `orders_service` para a mesma criação de pedido compartilham o mesmo
      `X-Correlation-Id` (valida também F02/F04 na prática).
- [ ] `docker compose restart orders_service` não apaga pedidos já criados.
