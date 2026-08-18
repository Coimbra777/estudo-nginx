# F01 — Plano de implementação

## Passos

1. Adicionar serviço `users_db` (`postgres:16-alpine`) ao `docker-compose.yml`, com
   volume próprio `users_db_data` — nunca reaproveitar `mysql_laravel_data`.
2. Adicionar `@nestjs/typeorm typeorm pg` em `nestjs-boilerplate-api/package.json`.
3. Criar a entidade TypeORM reaproveitando os campos já existentes em
   `src/users/entities/user.entity.ts` (`id`, `username`, `password`, `firstName`,
   `lastName`, `email`, `active`) — trocar `id: string` (hoje preenchido via
   `randomUUID()` no service) por coluna `uuid` com `@PrimaryGeneratedColumn('uuid')`.
4. Em `users.module.ts`, importar `TypeOrmModule.forFeature([User])` e configurar a
   conexão em `app.module.ts` via `TypeOrmModule.forRoot(...)` lendo as envs novas.
5. Reescrever `UsersService` trocando o array por `Repository<User>` injetado —
   manter os nomes de método (`create`, `findAll`, `findOne`, `update`, `remove`)
   inalterados, já que o controller depende deles.
6. Corrigir `findAll()` para `return this.usersRepository.find()`.
7. Adicionar `existsById(id: string): Promise<boolean>` no service e
   `GET /users/:id/exists` no controller.
8. Atualizar `Dockerfile`/`docker-compose.yml` com as envs de conexão do
   `users_db` (host, porta, usuário, senha, nome do banco).
9. Atualizar `users.service.spec.ts` para mockar o `Repository` (via
   `getRepositoryToken(User)`) em vez de inspecionar o array em memória.

## Riscos

- Senha de desenvolvimento do Postgres em texto plano no `docker-compose.yml` — é
  aceitável em ambiente de estudo, mas documentar explicitamente que produção exige
  segredo fora do compose (ex.: `.env` não versionado, ou secret manager).
- Trocar o tipo de `id` de UUID gerado em runtime para UUID gerado pelo banco pode
  quebrar algum teste que hardcoda um id — revisar `users.service.spec.ts` junto.

## Fora de escopo desta feature

- Hash de senha (ver `spec.md`).
- Qualquer mudança no `UsersController` além do novo endpoint `/exists` — o
  contrato público de F01 (seção "Provê" em `contract.md`) já é o que o controller
  atual expõe, só passa a ser persistido de verdade.
