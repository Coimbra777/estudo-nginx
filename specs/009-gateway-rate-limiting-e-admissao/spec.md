# F09 — Gateway: Rate Limiting e Admissão

**Provê:** `controle de admissão` — limite de taxa de requisições nas rotas
críticas de compra, com resposta `429` padronizada em vez de deixar o backend
absorver todo o pico.
**Consome:** `convenção de borda` (F02, mesma camada de headers/erro
padronizado).

## Contexto

Nenhuma proteção de taxa existe hoje no Nginx — qualquer volume de requisições
concorrentes chega direto em `orders_service`/`catalog_service`. Isso não era um
problema quando o objetivo era só "roteia certo"; agora que o case explícito é
"aguenta alta demanda", é o primeiro ponto de defesa antes de qualquer outra
coisa.

## Objetivo

Limitar a taxa de requisições por IP nas rotas de escrita mais sensíveis
(`POST /api/orders/`, `POST /api/catalog/*/reservations`), devolvendo `429` de
forma previsível em vez de deixar o backend saturar ou cair.

## Escopo

- `limit_req_zone` no Nginx, por IP (`$binary_remote_addr`), com uma zona
  dedicada para as rotas de compra.
- `limit_req` aplicado especificamente em `/api/orders/` (método `POST`) e
  `/api/catalog/*/reservations` — leitura (`GET /catalog/items`) não é limitada
  da mesma forma, já que ler o catálogo é exatamente o que se espera que
  aguente volume alto.
- Resposta `429` em JSON (reaproveitando o padrão de erro de upstream já criado
  em F02), não a página HTML default do Nginx.
- `burst` configurado para tolerar rajadas curtas legítimas sem começar a
  rejeitar no primeiro milissegundo de pico.

## Fora de escopo

- Fila de espera com posição visível ao comprador (virtual waiting room) — isso
  é uma feature de produto bem maior (precisaria de um serviço próprio de fila +
  UI); F09 entrega admissão binária (deixa passar ou `429`), não uma sala de
  espera.
- Rate limit diferenciado por usuário autenticado (vs. por IP) — usar IP é
  suficiente para o cenário de k6 (F10), que já simula IPs/conexões distintas
  por VU.

## Critérios de aceitação

- [ ] Disparar mais requisições que o limite configurado contra
      `POST /api/orders/` num curto intervalo produz `429` para o excedente,
      sem que `orders_service` chegue a processar essas requisições.
- [ ] `GET /api/catalog/items` continua respondendo normalmente mesmo durante um
      pico em `/api/orders/` — os limites são independentes por rota.
- [ ] O corpo do `429` é JSON (`{ "error": "rate limit exceeded" }`), consistente
      com o padrão de erro de F02.
