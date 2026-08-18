# F00 — Plano de implementação

## Por que essa feature vem antes das outras (sem ser uma dependência de contrato)

F01 e F03 já referenciam caminhos como `nestjs-boilerplate-api/src/users/...` e
`projeto-nest-1/src/...` nos próprios `spec.md`/`plan.md`. Isso **não** é uma
dependência de contrato no sentido do PRD (F01/F03 não consomem nada que F00
provê), mas é um conflito prático: se F00 rodar depois, os caminhos citados em
F01/F03 ficam desatualizados e alguém precisa lembrar de traduzir mentalmente
`nestjs-boilerplate-api` → `users-service`. Rodar F00 primeiro evita esse
retrabalho de leitura. Por isso ela está numerada `000` e em uma "wave 0" — não
porque o modelo de dependências exija, mas porque é a ordem que menos gera
confusão.

## Passos

1. `git mv nestjs-boilerplate-api users-service`
2. `git mv projeto-nest-1 orders-service`
   (usar `git mv`, não copiar+apagar, para preservar histórico do arquivo.)
3. Em `docker-compose.yml`:
   - `users_service.build.context`: `./nestjs-boilerplate-api` → `./users-service`
   - `users_service.volumes`: `./nestjs-boilerplate-api:/app` → `./users-service:/app`
   - `orders_service.build.context`: `./projeto-nest-1` → `./orders-service`
   - `orders_service.volumes`: `./projeto-nest-1:/app` → `./orders-service:/app`
   - `laravel.container_name`: `laravel_app` → `laravel`
   - `mysql-laravel.container_name`: `mysql_laravel` → `mysql-laravel`
   - `redis.container_name`: `redis_shared` → `redis`
   - Renomear a chave de serviço `nginx:` para `gateway:` (mantendo
     `image: nginx:alpine`, portas, volumes e `depends_on` como estão — só muda a
     chave); `container_name: nginx_gateway` → `container_name: gateway`.
4. `users-service/package.json`: `"name": "module1"` → `"name": "users-service"`.
5. `orders-service/package.json`: `"name": "projeto-nest-1"` → `"name": "orders-service"`.
6. No `Makefile`, trocar o **argumento** passado ao `docker compose` nos targets
   que hoje usam `nginx` (`up-nginx`, `restart-nginx`, `logs-nginx`, `bash-nginx`)
   para `gateway` — os *nomes* dos targets continuam os mesmos
   (`make up-nginx` etc.), só o que é passado para `$(DC) ...` muda.
7. Rodar `docker compose config` para validar que não sobrou nenhum caminho ou
   nome antigo.
8. Grep de segurança pra pegar qualquer referência residual:
   ```
   grep -rn "nestjs-boilerplate-api\|projeto-nest-1\|nginx_gateway\|laravel_app\|mysql_laravel\|redis_shared" \
     --include="*.yml" --include="Makefile" --include="*.md" --include="*.json" .
   ```
9. Depois do `git mv`, rodar `npm install` de novo dentro dos containers
   (`make npm-install-users`, `make npm-install-orders` do `Makefile`) em vez de
   tentar mover `node_modules` manualmente — o volume anônimo `/app/node_modules`
   do compose não se importa com o nome da pasta host, mas é mais seguro reinstalar
   do que confiar em um `node_modules` movido à mão.

## Riscos

- Se algo fora do repositório (IDE workspace salvo, scripts locais não versionados,
  aliases de shell do dia a dia) referenciar os caminhos antigos, só aparece depois
  — o grep do passo 8 cobre o que está versionado, não o ambiente local de quem
  desenvolve.
- Renomear a chave do compose `nginx` → `gateway` muda o nome usado em
  `docker compose logs -f <nome>` — quem tiver o hábito de digitar
  `docker compose logs -f nginx` direto (fora do Makefile) precisa se ajustar.
- `.vscode/settings.json` pode ter alguma referência de path — vale conferir
  manualmente, o grep do passo 8 já inclui esse tipo de arquivo se for JSON.

## Nota de compatibilidade com features já escritas

`specs/001-users-persistencia-e-correcao/` e `specs/003-orders-dominio-de-pedidos/`
citam os caminhos `nestjs-boilerplate-api/...` e `projeto-nest-1/...` porque foram
escritas **antes** desta feature existir, contra o estado real do repositório
naquele momento. Isso é proposital: os arquivos dessas specs descrevem o
repositório como ele é *hoje*, não como ficará depois de F00 rodar. Se F00 for
implementada antes de F01/F03, quem for implementá-las deve ler
`nestjs-boilerplate-api` como `users-service` e `projeto-nest-1` como
`orders-service` — a tradução é mecânica (1:1, ver tabela em `spec.md`), não
exige nenhuma decisão nova.

## Fora de escopo desta feature

Ver `spec.md` (domínio do Laravel, rotas HTTP, chaves `mysql-laravel`/`redis`).
