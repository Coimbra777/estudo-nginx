# F03 — Plano de implementação

## Pré-requisitos

- F01 concluída — `GET /users/:id/exists` precisa existir e responder de verdade.
- F02 concluída — o gateway precisa já estar propagando `X-Correlation-Id`.

## Passos

1. `nest g module orders && nest g controller orders && nest g service orders` em
   `projeto-nest-1/`.
2. Adicionar `orders_db` (`postgres:16-alpine`) ao `docker-compose.yml`, volume
   próprio `orders_db_data`, e `@nestjs/typeorm typeorm pg` ao `package.json` (o
   `projeto-nest-1` é Nest 11, então validar compatibilidade de versão do
   `@nestjs/typeorm` — usar a major mais recente compatível).
3. Criar entidade `Order` (ver modelo em `spec.md`).
4. Implementar `UsersClient` com `HttpModule`/`@nestjs/axios`, lendo
   `USERS_SERVICE_URL` do `ConfigModule` — nunca `http://users_service:3001`
   hardcoded no service.
5. `OrdersService.create(dto, correlationId)`:
   - chama `usersClient.exists(dto.userId, correlationId)`;
   - se `false`, lança `UnprocessableEntityException('user not found')`;
   - se `true`, persiste via `Repository<Order>`.
6. No `OrdersController`, extrair `X-Correlation-Id` via `@Headers()` e repassar
   para o service (não deixar o client HTTP gerar um novo id — o objetivo é
   rastrear a mesma requisição ponta a ponta).
7. Adicionar `USERS_SERVICE_URL=http://users_service:3001` como env do
   `orders_service` no `docker-compose.yml`.
8. Testes: mockar `UsersClient` em `orders.service.spec.ts` — teste unitário não
   deve bater na rede real.

## Riscos

- **Acoplamento síncrono**: se `users_service` cair, `orders_service` não cria
  pedidos. É um trade-off consciente desta fase (documentado também em
  `contract.md`), não um descuido — a evolução para um modelo assíncrono é a
  sugestão natural de próxima rodada, fora do escopo atual.
- `projeto-nest-1` está em Nest 11 e `nestjs-boilerplate-api` em Nest 8 — as duas
  integrações com TypeORM podem exigir versões de pacote diferentes; não copiar
  `package.json` de um serviço para o outro sem revisar.

## Fora de escopo desta feature

- Ver `spec.md` (evento assíncrono, cálculo de preço/estoque).
