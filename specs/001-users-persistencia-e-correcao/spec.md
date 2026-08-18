# F01 — Users Service: Persistência e Correção

**Provê:** `usuário persistido` — usuário com id estável, sobrevive a restart do
container, e um endpoint de existência consultável por outros serviços.
**Consome:** nada (feature-base, wave 1).

## Contexto

`nestjs-boilerplate-api/src/users/users.service.ts` guarda tudo em
`this.users: User[]`, um array em memória do processo Node — qualquer restart do
container `users_service` apaga todos os usuários. Além disso, `findAll()` tem um
bug:

```ts
public findAll() {
  return 'User list';
  // return this.users;
}
```

`GET /api/users/` nunca retornou a lista real. O `package.json` do serviço não tem
nenhum client de banco (`pg`, `mysql2`, `typeorm`, `prisma` — nada), então hoje é
literalmente impossível persistir sem adicionar dependências novas.

## Objetivo

Substituir o array em memória por um banco dedicado ao serviço (padrão
*database-per-service* — cada microsserviço é dono dos próprios dados, não
compartilha schema com o Laravel), corrigir o bug do `findAll`, e expor um endpoint
enxuto de existência de usuário para o `orders_service` consumir em F03.

## Escopo

- Banco **Postgres dedicado** (`users_db`), isolado do `mysql-laravel` — reforça o
  ponto pedagógico desta etapa: nenhum serviço lê a base de outro diretamente.
- Adicionar `@nestjs/typeorm`, `typeorm`, `pg` ao `nestjs-boilerplate-api`.
- Reescrever `UsersService` para persistir via `Repository<User>`, mantendo a
  interface pública do `UsersController` (não muda a assinatura dos métodos que o
  controller já chama).
- Corrigir `findAll()`.
- Novo endpoint `GET /users/:id/exists` → `{ exists: boolean }`, consumido pelo
  `orders_service` (F03) para validar `userId` sem expor o objeto usuário inteiro
  entre serviços.
- Variáveis de ambiente novas no `docker-compose.yml`: host/porta/usuário/senha/nome
  do `users_db`.

## Fora de escopo

- Hash de senha / autenticação real — o campo `password` continua como está; login
  de usuário final está fora do escopo deste PRD (seção 4).
- Ler o `PORT` de env em `main.ts` (hoje hardcoded em `3001`) — pequeno débito à
  parte, não bloqueia esta feature, mas vale corrigir junto se for mexer no arquivo.

## Critérios de aceitação

- [ ] `docker compose restart users_service` não apaga usuários criados antes do
      restart.
- [ ] `GET /api/users/` retorna um array JSON real, não mais a string `'User list'`.
- [ ] `GET /api/users/:id` retorna `404` padronizado (`{ statusCode, message }`)
      quando o id não existe.
- [ ] `GET /users/:id/exists` retorna `200 { exists: boolean }` para qualquer id,
      válido ou não (nunca 404 — é o contrato que F03 usa para decidir, não para
      navegar).
- [ ] `nestjs-boilerplate-api/package.json` inclui o client de banco escolhido.
