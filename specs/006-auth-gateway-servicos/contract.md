# F06 — Contrato

## Provê

- Toda rota de `users_service` e `orders_service`, **exceto `GET /health`** (F04),
  passa a exigir o header `X-Internal-Token`.
- Requisição sem o header correto → `401 { statusCode: 401, message: "Unauthorized" }`.

## Consome

- **F01** — logicamente protege os dados de usuário expostos pelo contrato de F01;
  não há chamada de API entre as duas, é uma relação de "F06 protege o que F01
  provê".
- **F02** — reaproveita o mesmo ponto de injeção de headers no Nginx
  (`proxy_set_header`) já usado para `X-Correlation-Id`.

## Consumido por

Nenhuma feature deste PRD depende de F06 — ela fecha o ciclo de segurança da wave
3. Uma feature futura de auth de usuário final (fora de escopo, ver PRD seção 4)
seria a próxima a se apoiar neste guard.
