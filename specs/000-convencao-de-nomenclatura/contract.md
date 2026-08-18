# F00 — Contrato

## Provê

- A tabela de convenção de nomenclatura (`spec.md`) — regra a seguir por qualquer
  feature futura que criar um novo serviço, banco ou container.
- Pastas `users-service/` e `orders-service/` no lugar de `nestjs-boilerplate-api/`
  e `projeto-nest-1/`.
- Chave de serviço `gateway` no lugar de `nginx` no `docker-compose.yml`.
- `container_name` alinhado à chave do serviço em `laravel`, `mysql-laravel` e
  `redis`.

## Consome

Nada.

## Consumido por

Nenhuma outra feature depende de F00 via contrato de API (não é um `provê`/`consome`
no sentido de dado ou endpoint). O acoplamento é só de **referência de caminho**:

- **F01** (`specs/001-.../spec.md` e `plan.md`) cita `nestjs-boilerplate-api/src/...`
  — depois de F00, esse caminho é `users-service/src/...`.
- **F03** (`specs/003-.../spec.md` e `plan.md`) cita `projeto-nest-1/` — depois de
  F00, esse caminho é `orders-service/`.

Nenhum `contract.md` de F01/F02/F03/F04/F05/F06 muda — os endpoints, as chaves de
serviço `users_service`/`orders_service`/`users_db`/`orders_db` e o
`REDIS_HOST=redis`/`DB_HOST=mysql-laravel` do Laravel continuam exatamente como
estão, porque esta feature deliberadamente não mexeu nessas chaves (ver "fora de
escopo" em `spec.md`).
