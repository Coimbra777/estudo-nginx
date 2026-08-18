# F02 — Plano de implementação

## Passos

1. No topo do `server {}` em `default.conf`, adicionar
   `add_header X-Correlation-Id $request_id always;` para expor o id também na
   resposta ao cliente.
2. Em cada bloco `location` que usa `proxy_pass` (`/api/users/`, `/api/orders/`),
   adicionar `proxy_set_header X-Correlation-Id $request_id;`.
3. No bloco `~ \.php$` (fastcgi), adicionar
   `fastcgi_param HTTP_X_CORRELATION_ID $request_id;` — Laravel recebe como
   `$_SERVER['HTTP_X_CORRELATION_ID']`.
4. Adicionar `proxy_connect_timeout 3s;` e `proxy_read_timeout 10s;` nos dois blocos
   de `proxy_pass`.
5. Adicionar:
   ```nginx
   error_page 502 504 = @upstream_error;
   location @upstream_error {
       default_type application/json;
       return 502 '{"error":"upstream unavailable"}';
   }
   ```
6. Validar manualmente: `docker compose stop users_service`, chamar
   `curl -i http://localhost:8080/api/users/`, confirmar `502` + corpo JSON.
7. Validar correlation-id: `curl -i http://localhost:8080/api/orders/` e conferir o
   header `X-Correlation-Id` na resposta.

## Riscos

- `$request_id` depende da versão do Nginx incluir o módulo core correspondente —
  `nginx:alpine` atual (linha `image: nginx:alpine` no compose) já atende; se a
  imagem for trocada por uma mais antiga no futuro, revalidar.
- Timeouts agressivos demais podem gerar falso-positivo de "upstream unavailable"
  em uma máquina de desenvolvimento lenta — os valores em `spec.md` são ponto de
  partida, não valor final.

## Fora de escopo desta feature

- Qualquer lógica de autenticação — ver F06.
- Rate limiting — ver `spec.md`.
