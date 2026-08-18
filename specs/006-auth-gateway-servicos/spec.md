# F06 — Autenticação entre Gateway e Serviços

**Provê:** `requisição autenticada internamente`.
**Consome:** `usuário persistido` (F01) · `convenção de borda` (F02).

## Contexto

Hoje qualquer requisição que chegue diretamente nos containers `users_service`,
`orders_service` ou `catalog_service` (F07) é aceita sem verificação — a rede Docker
(`microservices-network`) é a única barreira, e ela não impede tráfego lateral
entre containers (qualquer container na mesma rede bridge alcança as portas
internas 3000/3001 diretamente, ignorando o Nginx).

## Objetivo

Introduzir um token de serviço-a-serviço validado por um guard no Nest, como
primeiro passo antes de uma solução mais robusta (mTLS ou JWT assinado — fora de
escopo aqui). O objetivo desta feature não é autenticar o usuário final, é garantir
que só o gateway (ou serviços autorizados) consegue chamar `users_service`,
`orders_service` ou `catalog_service` diretamente.

## Escopo

- Segredo compartilhado `INTERNAL_GATEWAY_TOKEN`, como variável de ambiente do
  `nginx`, `users_service`, `orders_service` e `catalog_service`.
- Nginx injeta `X-Internal-Token: <segredo>` em todo `proxy_pass` para os três
  serviços Node — como `default.conf` é um arquivo estático hoje, isso exige usar
  `envsubst` no entrypoint da imagem (`nginx:alpine` já suporta processar templates
  em `/etc/nginx/templates/` via `/docker-entrypoint.d/20-envsubst-on-templates.sh`).
- Guard global (`APP_GUARD`) nos três serviços Node, rejeitando com `401`
  qualquer requisição sem o header correto.
- `orders_service` também precisa enviar o token quando chama `users_service`
  (F03) e `catalog_service` (F03/F07) — `UsersClient` e `CatalogClient` passam a
  incluir `X-Internal-Token` na chamada.

## Fora de escopo

- Autenticação de usuário final (login, JWT de sessão) — fora do escopo do PRD
  inteiro (seção 4).
- mTLS entre containers — o token compartilhado é um primeiro passo deliberadamente
  simples; documentar como tal, não apresentar como solução definitiva.
- Rotação automática do segredo.

## Critérios de aceitação

- [ ] Chamar `http://localhost:<porta-exposta-se-houver>/users` diretamente no
      `users_service`, sem o header correto, retorna `401`.
- [ ] Tráfego via `/api/users/` e `/api/orders/` continua funcionando normalmente —
      o Nginx injeta o header automaticamente, o cliente externo não precisa saber
      que ele existe.
- [ ] A chamada de `orders_service` para `users_service` (contrato de F03) continua
      funcionando com o guard ativo — precisa incluir o token também.
