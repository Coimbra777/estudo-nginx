# F04 — Plano de implementação

## Pré-requisitos

- F02 concluída — o header `X-Correlation-Id` precisa já existir para o log poder
  lê-lo.

## Passos

1. Adicionar `@nestjs/terminus` aos dois serviços Node; `GET /health` retornando
   `200 { status: "ok" }` (liveness puro, sem checar dependência externa).
2. Adicionar rota `GET /health` no Laravel — closure simples em `routes/web.php`
   retornando `response()->json(['status' => 'ok'])`, sem tocar banco/redis.
3. Adicionar `healthcheck:` a cada serviço relevante no `docker-compose.yml`:
   - `users_service`/`orders_service`: `curl -f http://localhost:<porta>/health`
     (a imagem `node:20-alpine` não tem `curl` por padrão — avaliar `wget` ou
     instalar `curl` no `Dockerfile`).
   - `laravel`: idem, apontando para o `/health` novo.
   - `mysql-laravel`, `redis`, `users_db`, `orders_db`: healthchecks padrão de
     imagem oficial (`mysqladmin ping`, `redis-cli ping`, `pg_isready`).
4. Trocar `depends_on: [a, b]` (forma curta) do `nginx` pela forma longa com
   `condition: service_healthy` para `laravel`, `users_service`, `orders_service`.
5. Adicionar interceptor de log (Nest `Interceptor` global ou middleware) que lê
   `req.headers['x-correlation-id']` e inclui em todo log da requisição — pode ser
   um logger simples (`console.log` estruturado em JSON) ou `nestjs-pino`, a critério
   de quem implementar; o contrato é o campo `correlationId` presente na linha de
   log, não a lib escolhida.

## Riscos

- Adicionar `curl`/`wget` às imagens Node aumenta levemente o tamanho da imagem —
  aceitável para ambiente de estudo.
- `condition: service_healthy` exige Compose v2 (já é o caso, o `Makefile` usa
  `docker compose`, não `docker-compose`).

## Fora de escopo desta feature

- Ver `spec.md` (stack externa de observabilidade).
