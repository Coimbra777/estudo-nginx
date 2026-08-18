# F02 — Gateway: Convenções Transversais

**Provê:** `convenção de borda` — correlation-id, timeouts explícitos e formato de
erro padronizado para upstream fora do ar.
**Consome:** nada (feature-base, wave 1).

## Contexto

`docker/nginx/default.conf` hoje faz `proxy_pass`/`fastcgi_pass` puro: não injeta
nenhum cabeçalho de correlação, não define timeout explícito (fica no default do
Nginx), e um upstream fora do ar (ex.: `users_service` parado) cai na página HTML
de erro padrão do Nginx — inconsistente com o resto da API, que fala JSON.

## Objetivo

Fazer o Nginx gerar e propagar um `X-Correlation-Id` por requisição para os
destinos (`laravel`, `users_service`, `orders_service`, e agora também
`catalog_service` — F07), padronizar timeouts, e devolver JSON em vez de HTML
quando um upstream não responde. Esta feature é pré-requisito de F03 (orders
precisa repassar o correlation-id), F04 (observabilidade precisa dele para
correlacionar logs entre serviços) e F09 (rate limiting reaproveita o mesmo
padrão de erro JSON para o corpo do `429`).

## Escopo

- Usar `$request_id` (nativo do Nginx ≥ 1.11, presente em `nginx:alpine` atual) e
  propagar como `X-Correlation-Id` via `proxy_set_header`/`fastcgi_param` nos
  blocos de `location` existentes (`/`, `/api/users/`, `/api/orders/`,
  `/api/catalog/`, `~ \.php$`).
- `proxy_connect_timeout` / `proxy_read_timeout` explícitos (valores de estudo —
  documentar que em produção seriam calibrados por serviço, não um valor único).
- `error_page 502 504` apontando para uma resposta JSON padronizada, em vez da
  página HTML default.

## Fora de escopo

- Autenticação (F06) — este bloco só padroniza cabeçalho e erro, não valida nada.
- Rate limiting — passou a ser uma feature própria (F09), não faz parte deste
  bloco; F09 só reaproveita o formato de erro JSON criado aqui.

## Critérios de aceitação

- [ ] Toda resposta de `/api/users/*` e `/api/orders/*` inclui `X-Correlation-Id`
      no header de resposta.
- [ ] `docker compose stop users_service` seguido de uma chamada a
      `/api/users/` retorna JSON `{ "error": "upstream unavailable" }` com status
      `502`, não a página HTML padrão do Nginx.
