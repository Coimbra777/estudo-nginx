# F07 — Plano de implementação

## Passos

1. Criar a pasta `catalog-service/` já seguindo a convenção de F00 (não precisa
   de rename posterior).
2. `catalog_db` (Postgres) + `@nestjs/typeorm typeorm pg` (mesmo padrão de
   F01/F03).
3. Entidades `CatalogItem` e `Reservation` (ver modelo em `spec.md`).
4. Script Lua de reserva atômica:
   ```lua
   local available = tonumber(redis.call('GET', KEYS[1]) or '0')
   local qty = tonumber(ARGV[1])
   if available >= qty then
     redis.call('DECRBY', KEYS[1], qty)
     return 1
   end
   return 0
   ```
   Chamado via `EVAL` — garante que "checar e decrementar" seja uma única
   operação atômica no Redis, mesmo com múltiplas requisições simultâneas.
5. `CatalogService.reserve(itemId, quantity)`:
   - roda o script Lua contra `catalog:available:<itemId>`;
   - se retornar `1`, persiste `Reservation` no Postgres com `status: "pending"`
     e `expiresAt = now + 5min`;
   - se retornar `0`, responde `409`.
6. `confirm(reservationId)`: valida `status === "pending"` e `expiresAt > now`;
   se ok, marca `confirmed` e decrementa `quantityTotal` no Postgres. Se
   expirado, `410` — e libera o contador do Redis nesse momento, já que a
   expiração só foi percebida agora (expiração preguiçosa, ver `spec.md`).
7. `release(reservationId)`: marca `released` e devolve a quantidade ao contador
   Redis (`INCRBY`).
8. Rehidratação do Redis: no boot do serviço, para cada `CatalogItem`, calcular
   `available = quantityTotal - soma(reservations pending/confirmed não
   liberadas)` e fazer `SET catalog:available:<id>`.
9. Testes: cenário de concorrência simulando N chamadas paralelas a `reserve()`
   contra estoque pequeno via `Promise.all` no teste unitário/integração — o
   cenário de volume real, contra o sistema inteiro, é F10.

## Riscos

- O script Lua roda no mesmo Redis usado por F05 (Laravel) — sem problema
  técnico, mas o prefixo `catalog:` evita colisão com chaves de cache/sessão do
  Laravel.
- Se o Redis cair, o caminho quente de reserva para — é uma dependência crítica
  nova, diferente do resto do projeto (onde Redis era só cache). Documentar
  esse trade-off como aceito nesta fase; um fallback para
  `SELECT ... FOR UPDATE` no Postgres é a evolução natural, fora de escopo.

## Fora de escopo desta feature

Ver `spec.md`.
