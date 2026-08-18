# F05 — Ativação do Redis

**Provê:** `cache/fila ativos` no Laravel.
**Consome:** nada (feature-base, wave 1).

## Contexto

`redis_shared` já sobe no `docker-compose.yml` e `REDIS_HOST=redis` já está no
`.env.example` do Laravel, mas `CACHE_DRIVER=file`, `SESSION_DRIVER=file` e
`QUEUE_CONNECTION=sync` continuam nos valores padrão — o Redis existe na rede, mas
nenhum driver do Laravel efetivamente o lê. A extensão PHP `redis` já é instalada
no `Dockerfile` (`pecl install -o -f redis`), então a única lacuna é configuração,
não infraestrutura.

## Objetivo

Trocar os três drivers para `redis` de fato e validar manualmente que cache,
sessão e fila passam a usar o container `redis_shared`.

## Escopo

- `.env` do container Laravel (não o `.env.example`, que é só template):
  `CACHE_DRIVER=redis`, `SESSION_DRIVER=redis`, `QUEUE_CONNECTION=redis`.
- Validação manual via `artisan tinker`.

## Fora de escopo

- Qualquer job de fila real — não existe trabalho assíncrono no Laravel hoje;
  `QUEUE_CONNECTION=redis` fica "pronto para uso" sem um caso de uso para provar,
  o que é aceitável nesta fase (documentado, não escondido).
- Redis como bus de eventos entre `users_service`/`orders_service` — cogitado como
  evolução futura (ver PRD, seção "fora de escopo"), não faz parte desta feature.

## Critérios de aceitação

- [ ] `php artisan tinker` → `Cache::put('ping', 'pong', 60)` grava uma chave
      visível via `redis-cli -h redis KEYS '*'` a partir de outro container na
      mesma rede.
- [ ] Sessão do Laravel sobrevive a um `docker compose restart laravel` (hoje, com
      `SESSION_DRIVER=file`, isso depende do volume montado; com Redis o
      comportamento fica correto mesmo sem volume compartilhado de sessão).
