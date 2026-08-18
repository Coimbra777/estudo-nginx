# F05 — Plano de implementação

## Passos

1. No `.env` do container Laravel (criado a partir do `.env.example` pelo target
   `laravel-env` do `Makefile`), trocar:
   - `CACHE_DRIVER=file` → `CACHE_DRIVER=redis`
   - `SESSION_DRIVER=file` → `SESSION_DRIVER=redis`
   - `QUEUE_CONNECTION=sync` → `QUEUE_CONNECTION=redis`
2. Confirmar que `REDIS_HOST=redis`, `REDIS_PORT=6379`, `REDIS_PASSWORD=null` já
   apontam corretamente para o container `redis_shared` (já estão corretos no
   `.env.example` atual).
3. Rodar `make artisan cmd="config:clear"` (o Laravel cacheia config e não pega a
   mudança de driver sem isso).
4. Validar manualmente:
   ```
   make bash-laravel
   php artisan tinker
   >>> Cache::put('ping', 'pong', 60);
   >>> Cache::get('ping');
   ```
5. Confirmar via `docker compose exec redis redis-cli KEYS '*'` que a chave
   apareceu no container certo.

## Riscos

- Nenhum job de fila real existe para validar `QUEUE_CONNECTION=redis` fim a fim —
  a validação fica limitada a "o driver está configurado e o cache funciona";
  documentar essa limitação em vez de fingir cobertura completa.
- `config:clear` precisa ser rodado toda vez que o `.env` mudar em ambiente com
  cache de config ativo — comum esquecer e achar que a mudança "não funcionou".

## Fora de escopo desta feature

- Ver `spec.md` (job de fila real, Redis como bus de eventos).
