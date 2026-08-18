# F06 — Plano de implementação

## Pré-requisitos

- F01 e F02 concluídas.
- Idealmente depois de F03/F04 estarem estáveis — este guard afeta toda chamada
  entre `orders_service` e `users_service`, então é mais seguro validar com esse
  fluxo já funcionando sem autenticação antes de adicionar mais uma variável.

## Passos

1. Definir `INTERNAL_GATEWAY_TOKEN` no `docker-compose.yml` como env compartilhada
   entre `nginx`, `users_service`, `orders_service` e `catalog_service` (mesmo
   valor em todos — em produção seria um secret gerenciado, aqui é uma env de
   estudo).
2. Mover `default.conf` para `docker/nginx/templates/default.conf.template` e
   trocar `proxy_pass`/valores fixos por variáveis de ambiente onde necessário,
   usando a sintaxe `${INTERNAL_GATEWAY_TOKEN}` — a imagem `nginx:alpine`
   processa arquivos em `/etc/nginx/templates/*.template` com `envsubst`
   automaticamente antes do `nginx` iniciar.
3. Adicionar `proxy_set_header X-Internal-Token ${INTERNAL_GATEWAY_TOKEN};` nos
   blocos `/api/users/`, `/api/orders/` e `/api/catalog/`.
4. Criar `InternalTokenGuard implements CanActivate` em cada serviço Node, lendo
   `process.env.INTERNAL_GATEWAY_TOKEN` e comparando com
   `request.headers['x-internal-token']`; registrar como `APP_GUARD` no módulo
   raiz.
5. Atualizar `UsersClient` e `CatalogClient` de `orders_service` (F03) para
   incluir `X-Internal-Token` nas chamadas a `users_service` e
   `catalog_service`.
6. Atualizar `.env.example` e o `Makefile`/README com a nova variável, documentando
   que é um segredo de desenvolvimento, não apto para produção como está.

## Riscos

- Guard global pode quebrar o próprio healthcheck de F04 (`GET /health`) se o
  healthcheck do compose não incluir o header — **decisão**: `/health` deve ficar
  fora do guard (rota de liveness não deve exigir segredo de aplicação), usando
  `@Public()` decorator ou checagem de path no guard.
- Migrar `default.conf` para template muda o caminho do arquivo montado no
  `docker-compose.yml` (`volumes:` do serviço `nginx`) — atualizar o mount de
  `./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf` para o novo padrão
  de template.

## Fora de escopo desta feature

- Ver `spec.md` (mTLS, rotação de segredo, auth de usuário final).
