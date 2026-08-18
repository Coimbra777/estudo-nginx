# F00 — Convenção de Nomenclatura de Serviços e Domínios

**Provê:** `convenção de nomenclatura` — nome de pasta, chave de serviço no
compose, `container_name` e nome de pacote alinhados ao domínio de negócio de cada
serviço.
**Consome:** nada (feature-base). Fica em uma **wave 0** própria — sem dependência
de contrato com ninguém, mas recomendada antes das demais por motivo prático, não
arquitetural (ver `plan.md`).

## Contexto

Levantamento do estado atual do repositório: nada aqui é "errado" a ponto de
quebrar, mas a nomenclatura não comunica domínio, e diverge de arquivo pra arquivo.

- **Pasta de projeto não reflete o domínio**: `nestjs-boilerplate-api` (é o
  serviço de *users*), `projeto-nest-1` (é o serviço de *orders*), `projeto-laravel`
  (domínio de negócio resolvido pela revisão 2 do PRD — é a *storefront*, ver F08 —
  mas o nome da pasta ainda não reflete isso; ver "decisão" abaixo).
- **`container_name` diverge da chave do serviço** em 3 dos 6 containers do
  `docker-compose.yml`: chave `laravel` → `container_name: laravel_app`; chave
  `mysql-laravel` → `container_name: mysql_laravel`; chave `redis` →
  `container_name: redis_shared`. Só `users_service`/`orders_service` já usam o
  mesmo nome nos dois lugares.
- **Nome de pacote não comunica nada**: `nestjs-boilerplate-api/package.json` →
  `"name": "module1"`; `projeto-nest-1/package.json` → `"name": "projeto-nest-1"`
  (nome de pasta, não de domínio); `projeto-laravel/composer.json` →
  `"name": "laravel/laravel"` (nome padrão do skeleton, nunca trocado).
- **Bancos novos já nascem corretos**: `users_db` (F01) e `orders_db` (F03) já
  seguem `<domínio>_db` — bom precedente, ainda não documentado como regra.

## Objetivo

Documentar e aplicar uma convenção única de nomenclatura para os serviços que já
têm domínio de negócio claro (users, orders, e agora catalog — F07), alinhar
`container_name` à chave de serviço nos containers restantes, e trocar a chave
`nginx` por `gateway`. A pasta/chave do Laravel fica como está por decisão
explícita (não por falta de domínio — isso já foi resolvido por F08), ver
"Decisão — nome do Laravel" abaixo.

## Convenção proposta

| Papel | Pasta | Chave no compose | `container_name` | Nome de pacote |
|---|---|---|---|---|
| Serviço de domínio | `<domínio>-service` (kebab-case) | `<domínio>_service` (snake_case) | igual à chave | igual à pasta |
| Banco de um serviço | — | `<domínio>_db` | igual à chave | — |
| Infra compartilhada (sem domínio próprio) | — | nome descritivo do papel | igual à chave | — |
| Gateway | — | `gateway` | igual à chave | — |

## Tabela de mudanças

| Papel | Pasta atual → nova | Chave atual → nova | `container_name` atual → novo | Pacote atual → novo |
|---|---|---|---|---|
| Users | `nestjs-boilerplate-api` → `users-service` | `users_service` (sem mudança) | `users_service` (sem mudança) | `module1` → `users-service` |
| Orders | `projeto-nest-1` → `orders-service` | `orders_service` (sem mudança) | `orders_service` (sem mudança) | `projeto-nest-1` → `orders-service` |
| Storefront (domínio: F08) | `projeto-laravel` (sem mudança — ver decisão abaixo) | `laravel` (sem mudança) | `laravel_app` → `laravel` | `laravel/laravel` (sem mudança) |
| Banco da storefront | — | `mysql-laravel` (sem mudança) | `mysql_laravel` → `mysql-laravel` | — |
| Catalog (F07) | `catalog-service` (nasce correta) | `catalog_service` (nasce correta) | `catalog_service` (nasce correta) | `catalog-service` (nasce correta) |
| Cache compartilhado | — | `redis` (sem mudança) | `redis_shared` → `redis` | — |
| Gateway | — | `nginx` → `gateway` | `nginx_gateway` → `gateway` | — |
| Banco de users (F01) | — | `users_db` (já correto) | — | — |
| Banco de orders (F03) | — | `orders_db` (já correto) | — | — |
| Banco de catalog (F07) | — | `catalog_db` (já correto) | — | — |

Só a troca de `nginx` → `gateway` mexe numa **chave de serviço** (o nome usado
para resolução DNS entre containers na rede do compose); todo o resto é
`container_name` (cosmético, não afeta como os serviços se enxergam) ou pasta/nome
de pacote (não afeta o runtime). É por isso que essa troca é segura mesmo sem
tocar em nenhum outro serviço: nada no projeto chama o Nginx pelo nome — ele só é
acessado de fora, pela porta publicada 8080.

## Decisão — nome do Laravel

**Resolvido.** A revisão 2 do PRD definiu o domínio: o Laravel é a *storefront*
(F08) — loja e checkout. A pasta/chave, ainda assim, ficam como estão
(`projeto-laravel` / `laravel`), por decisão explícita, não por falta de nome: F08
também decidiu que a storefront não é dona de nenhum dado de negócio (nem
catálogo, nem pedido, nem usuário) — ela só orquestra chamadas a F01/F03/F07. Um
serviço "fino" desse tipo tem menos a ganhar com um rename de pasta/container do
que os serviços de domínio de verdade (users, orders, catalog); o custo de mover
arquivos e atualizar `default.conf`/Makefile não se paga aqui. Se isso mudar —
por exemplo, se a storefront ganhar responsabilidade própria de dado no futuro —
vale reabrir esta decisão.

## Fora de escopo

- Renomear a pasta/chave do Laravel para algo como `storefront` — ver decisão
  acima; o nome fica como está por ora.
- Renomear rotas HTTP (`/api/users/`, `/api/orders/`) — já estão alinhadas ao
  domínio, não fazem parte desta feature.
- Renomear a chave `mysql-laravel` ou `redis` — cascatearia para variáveis de
  ambiente (`DB_HOST`, `REDIS_HOST`) e outras features (F05); o ganho de clareza
  não paga o custo de coordenação nesta rodada.

## Critérios de aceitação

- [ ] `nestjs-boilerplate-api/` e `projeto-nest-1/` não existem mais; `users-service/`
      e `orders-service/` existem no lugar, com histórico de git preservado
      (`git log --follow` funciona).
- [ ] `docker compose config` não gera erro após a troca de pastas/chaves — os
      caminhos de `build.context` e `volumes` estão atualizados.
- [ ] `docker compose ps` mostra `container_name` igual à chave do serviço para
      todos os containers, exceto os que a spec marcou como fora de escopo.
- [ ] `users-service/package.json` e `orders-service/package.json` têm `"name"`
      igual ao nome da pasta.
- [ ] `make up-nginx`, `make logs-nginx`, `make bash-nginx`, `make restart-nginx`
      continuam funcionando (o nome do target do Makefile não muda, só o argumento
      interno passado ao `docker compose`).
