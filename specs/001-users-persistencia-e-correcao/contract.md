# F01 — Contrato

## Provê

| Rota | Resposta |
|---|---|
| `GET /users` | `200 [{ id, username, firstName, lastName, email, active }]` |
| `GET /users/:id` | `200 { id, username, firstName, lastName, email, active }` \| `404 { statusCode: 404, message: "User not found" }` |
| `GET /users/:id/exists` | `200 { exists: boolean }` — **nunca 404**, é o contrato estável que F03 (Orders) consome |
| `POST /users` | `201 { ...user }` — corpo: `{ username, password, firstName, lastName, email }` |
| `PATCH /users/:id` | `200 { ...user atualizado }` |
| `DELETE /users/:id` | `204` |

Formato de erro padrão: `{ statusCode: number, message: string }` (herdado das
exceptions nativas do Nest — `NotFoundException`, etc.).

Roteado externamente via gateway em `/api/users/*` (ver F02 — o prefixo é
removido pelo Nginx antes de chegar aqui; internamente as rotas seguem sem prefixo,
como já estão hoje).

## Consome

Nada. F01 é uma feature-base.

## Consumido por

- **F03 (Orders Service)** — usa `GET /users/:id/exists` para validar `userId`
  antes de criar um pedido. Qualquer mudança no formato de resposta deste endpoint
  é uma mudança de contrato e exige atualizar `specs/003-.../contract.md` junto.

## Versionamento

Sem prefixo de versão por enquanto (`/users`, não `/v1/users`). Introduzir
versionamento fica para quando existir um segundo consumidor externo além do
gateway/orders_service — não faz sentido versionar um contrato com um único
consumidor interno.
