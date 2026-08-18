# F03 — Plano de implementação

## Pré-requisitos

- F01 concluída — `GET /users/:id/exists` precisa existir e responder de
  verdade.
- F02 concluída — o gateway precisa já estar propagando `X-Correlation-Id`.
- F07 concluída — `POST /catalog/items/:id/reservations` e
  `.../confirm`/`.../release` precisam existir e responder de verdade.

## Passos

1. `nest g module orders && nest g controller orders && nest g service orders`
   em `projeto-nest-1/` (ou `orders-service/`, se F00 já rodou — ver nota de
   compatibilidade em `specs/000-.../plan.md`).
2. Adicionar `orders_db` (`postgres:16-alpine`) ao `docker-compose.yml`, volume
   próprio `orders_db_data`, e `@nestjs/typeorm typeorm pg` ao `package.json`
   (validar compatibilidade de versão do `@nestjs/typeorm` com o Nest 11 usado
   aqui).
3. Criar entidade `Order` (ver modelo em `spec.md`) — `items` como coluna JSON,
   guardando `catalogItemId`, `quantity` e `reservationId` por linha.
4. Implementar `UsersClient` (chama F01) e `CatalogClient` (chama F07), ambos
   com `HttpModule`/`@nestjs/axios`, lendo `USERS_SERVICE_URL` e
   `CATALOG_SERVICE_URL` do `ConfigModule` — nunca hostname hardcoded.
5. `OrdersService.create(dto, correlationId)`:
   - chama `usersClient.exists(dto.userId, correlationId)`; se `false`, lança
     `UnprocessableEntityException('user not found')`;
   - para cada item de `dto.items`, chama
     `catalogClient.reserve(catalogItemId, quantity, correlationId)`;
   - se alguma reserva falhar, chama `catalogClient.release(...)` para as
     reservas já feitas nesta mesma chamada (compensação) e lança
     `ConflictException('insufficient_stock')`;
   - se todas as reservas foram bem-sucedidas, persiste `Order` com
     `status: "pending_payment"` e os `reservationId`s retornados.
6. `OrdersService.confirm(orderId, correlationId)`: para cada item do pedido,
   chama `catalogClient.confirm(reservationId, correlationId)`; muda
   `status` para `confirmed`.
7. `OrdersService.cancel(orderId, correlationId)`: para cada item, chama
   `catalogClient.release(reservationId, correlationId)`; muda `status` para
   `cancelled`.
8. No `OrdersController`, extrair `X-Correlation-Id` via `@Headers()` e
   repassar para o service em toda chamada — não deixar os clients HTTP
   gerarem um novo id.
9. Adicionar `USERS_SERVICE_URL=http://users_service:3001` e
   `CATALOG_SERVICE_URL=http://catalog_service:<porta>` como env do
   `orders_service` no `docker-compose.yml`.
10. Testes: mockar `UsersClient` e `CatalogClient` em `orders.service.spec.ts` —
    teste unitário não deve bater na rede real; cobrir explicitamente o caminho
    de compensação (reserva parcial falha, as demais são liberadas).

## Riscos

- **Acoplamento síncrono duplo**: se `users_service` **ou** `catalog_service`
  cair, `orders_service` não cria pedidos. Mais um serviço crítico no caminho
  do que na revisão anterior deste PRD — trade-off aceito nesta fase (ver
  `contract.md`), evolução para modelo assíncrono fica fora do escopo atual.
- **Compensação não é transação distribuída de verdade**: se `orders_service`
  cair depois de reservar em F07 mas antes de persistir o `Order`, a reserva
  fica órfã até o TTL dela expirar (F07 já cobre isso via expiração
  preguiçosa) — não é perda de estoque, só uma reserva temporariamente presa.
  Documentar como comportamento aceito, não como bug.
- `orders-service` está em Nest 11 e `users-service` em Nest 8 (ver F00) — as
  integrações com TypeORM podem exigir versões de pacote diferentes; não
  copiar `package.json` de um serviço para o outro sem revisar.

## Fora de escopo desta feature

Ver `spec.md`.
