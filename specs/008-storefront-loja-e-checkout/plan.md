# F08 — Plano de implementação

## Pré-requisitos

- F01, F03, F07 concluídas — a storefront não tem lógica própria, só orquestra
  chamadas a elas.

## Passos

1. `routes/web.php`: rota `GET /catalog` → controller que chama
   `GET <CATALOG_SERVICE_URL>/catalog/items` (via `Http::get`, client HTTP do
   Laravel, lendo a URL base de `config/services.php`/env — nunca hardcoded).
2. `POST /checkout`: recebe `userId` + itens do carrinho (sessão Redis), chama
   `POST <ORDERS_SERVICE_URL>/orders`, repassa o resultado para a view.
3. Sessão do carrinho: usar `session()` do Laravel, já apontando para o Redis via
   F05 (`SESSION_DRIVER=redis`) — carrinho é só uma lista de
   `{ catalogItemId, quantity }` na sessão até o checkout.
4. Views Blade mínimas — uma listagem de catálogo, uma tela de
   confirmação/erro. Sem investimento em CSS/design (fora de escopo, ver
   `spec.md`).
5. Variáveis de ambiente novas: `CATALOG_SERVICE_URL`, `ORDERS_SERVICE_URL`,
   `USERS_SERVICE_URL` no `.env`/compose do Laravel.
6. Propagar `X-Correlation-Id` (F02) nas chamadas HTTP feitas pela storefront —
   mesma convenção que F03 já segue ao chamar F01.

## Riscos

- Acoplamento síncrono a três serviços no caminho de checkout (Users, Orders, e
  indiretamente Catalog via Orders) — se qualquer um cair, o checkout cai
  junto. Trade-off aceito nesta fase, mesmo espírito do risco já registrado em
  F03.
- Sanctum ainda existe no Laravel por padrão do framework — esta feature não
  remove o pacote, só evita usá-lo como fonte de identidade; documentar isso
  para não confundir alguém que veja `laravel/sanctum` no `composer.json` e
  assuma que há login local.

## Fora de escopo desta feature

Ver `spec.md`.
