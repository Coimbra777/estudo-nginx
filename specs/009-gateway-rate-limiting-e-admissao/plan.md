# F09 — Plano de implementação

## Pré-requisitos

- F02 concluída (formato de erro padronizado e correlation-id já existem, esta
  feature reaproveita o mesmo padrão para o corpo do `429`).

## Passos

1. No bloco `http {}` (ou equivalente, conforme a estrutura do `default.conf`),
   declarar:
   ```nginx
   limit_req_zone $binary_remote_addr zone=purchase_zone:10m rate=10r/s;
   ```
2. No `location /api/orders/`, dentro do bloco que já existe (F02 adicionou
   correlation-id/timeout ali):
   ```nginx
   limit_req zone=purchase_zone burst=20 nodelay;
   limit_req_status 429;
   ```
3. Repetir para reservas de catálogo — se `/api/catalog/` tiver rotas de leitura
   e escrita sob o mesmo prefixo, usar um `location` mais específico
   (`~ ^/api/catalog/.*/reservations$`) para não limitar leitura.
4. `error_page 429` apontando para o mesmo padrão JSON criado em F02 para
   502/504, com mensagem específica.
5. Validar com uma rajada local (`ab`/`hey`/`wrk` contra `/api/orders/`) e
   confirmar que o excedente recebe `429` — a validação completa sob volume real
   é responsabilidade de F10.

## Riscos

- `rate=10r/s`/`burst=20` são valores de partida para ambiente de estudo — não
  foram calibrados contra capacidade real de `orders_service`/`catalog_service`;
  o cenário de F10 é exatamente o que informa se esses números fazem sentido.
- Rate limit por IP único (`$binary_remote_addr`) pode punir múltiplos usuários
  atrás do mesmo NAT/proxy corporativo — aceitável para o escopo deste PRD, não
  para produção real.

## Fora de escopo desta feature

Ver `spec.md`.
