# F08 — Storefront (Laravel): Loja e Checkout

**Provê:** `experiência de compra` — navegação de catálogo e checkout, usando o
Laravel como cliente dos demais serviços, não como dono de dado de negócio.
**Consome:** `disponibilidade reservável` (F07) · `pedido confirmado` (F03) ·
`usuário persistido` (F01).

## Contexto

Na primeira revisão deste PRD, o domínio de negócio do Laravel estava marcado
como decisão pendente em F00 — ele não tinha nenhuma rota além do `/user` padrão
do Sanctum. Esta feature fecha essa decisão: o Laravel vira a storefront do
case — a aplicação que o comprador acessa para ver o catálogo e comprar.

## Decisão de arquitetura: sem tabela de usuário própria

O Laravel tem, por padrão, uma tabela `users` (Sanctum). Manter essa tabela como
fonte de identidade duplicaria o que F01 (Users Service) já é dono — quebraria o
princípio de *database-per-service* que o resto do PRD segue. Esta feature
assume que a storefront **não autentica localmente**: identifica o comprador
chamando `GET /users/:id/exists` (F01) e trata a sessão/carrinho via Redis (F05),
não via uma tabela `users` própria. Login/senha completos continuam fora de
escopo (`PRD.md`, seção 4) — o comprador é identificado por um `userId` já
existente, não por um formulário de cadastro.

## Escopo

- Rota de catálogo: consome `GET /catalog/items` (F07) e lista ingressos/produtos
  disponíveis.
- Rota de checkout: recebe `{ userId, items }`, chama `POST /orders` (F03) e
  mostra o resultado (confirmado ou estoque insuficiente).
- Sessão/carrinho em Redis (reaproveitando F05, driver `SESSION_DRIVER=redis` já
  ativo).
- **Sem view HTML elaborada** — o foco desta rodada é o fluxo de dados
  (catálogo → pedido → confirmação) funcionando ponta a ponta, testável tanto
  por um humano quanto pelo k6 (F10). Views Blade mínimas, sem investimento em
  design/UX.

## Fora de escopo

- Registro de novo comprador / recuperação de senha — ver `PRD.md`, seção 4.
- Carrinho persistente entre dispositivos, cupom, frete — não fazem parte do
  case de alta demanda que este PRD testa.
- Qualquer dado de negócio (ingresso, produto, pedido) armazenado no MySQL do
  Laravel — se algo precisa persistir, pertence a F01/F03/F07, não à storefront.

## Critérios de aceitação

- [ ] A storefront completa `catálogo → checkout → pedido confirmado` chamando
      só os contratos HTTP de F01/F03/F07 — nenhuma escrita em tabela de negócio
      própria do Laravel.
- [ ] Um `userId` inexistente no checkout retorna erro claro ao comprador (não
      uma exceção genérica) — repassando o `422`/`404` de F01/F03.
- [ ] Estoque insuficiente (F07 retornando `409`) aparece ao comprador como
      "esgotado", não como erro genérico de servidor.
