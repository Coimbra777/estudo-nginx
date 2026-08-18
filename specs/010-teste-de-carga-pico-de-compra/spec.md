# F10 — Teste de Carga: Cenário de Pico de Compra

**Provê:** `evidência de comportamento sob carga` — um cenário reproduzível que
prova (ou derruba) a garantia central deste PRD: zero overselling sob alta
concorrência.
**Consome:** `pedido confirmado` (F03, via gateway) · observa `controle de
admissão` (F09) e `ambiente observável` (F04).

## Contexto

Esta é a feature que fecha o ciclo: todo o resto do PRD (catálogo com reserva
atômica, orders orquestrando a compra, gateway com rate limit, observabilidade)
existe para sobreviver a este cenário. Sem ela, as garantias de F07/F09 ficam
sem prova.

## Objetivo

Simular um pico de compra realista — muitos compradores concorrentes disputando
um estoque pequeno e fixo — e medir: taxa de erro, latência, quantos pedidos
confirmam de fato, e se esse número bate exatamente com o estoque configurado.

## Ferramenta

[k6](https://k6.io) — scripts em JavaScript, thresholds declarativos, roda tanto
localmente quanto em CI, boa métrica de saída (p95/p99, taxa de erro).

## Cenário

1. Seed: criar 1 `CatalogItem` do tipo `ticket` com `quantityTotal` pequeno (ex.:
   100) via F07, e N usuários pré-existentes via F01 (ex.: 1000).
2. Ramp-up: 500 *virtual users* subindo em 30s, cada um tentando
   `POST /api/orders/` comprando 1 unidade do mesmo ingresso.
3. Sustentação: manter os 500 VUs por 1 minuto tentando repetidamente (com
   pequeno *think time*) até o estoque esgotar.
4. Medir:
   - quantos pedidos confirmaram (`status: "confirmed"`) — **tem que ser
     exatamente 100**, nem mais, nem menos;
   - taxa de `409` (estoque esgotado) — esperada, não é falha;
   - taxa de `429` (rate limit de F09) — esperada sob pico, não é falha;
   - taxa de `5xx` — **essa sim é falha**, não deveria existir;
   - p95/p99 de latência das requisições que passaram.

## Escopo

- Diretório `loadtest/` na raiz, com o script k6 (`purchase-peak.js`) e um
  script de seed (via API, chamando F01/F07 antes do teste).
- `thresholds` do k6 codificando os critérios de aceitação abaixo, para o teste
  falhar sozinho se a garantia quebrar — não depender de leitura manual do
  relatório.
- Alvo do teste: o gateway (`http://localhost:8080/api/...`), não os serviços
  diretamente — é o caminho real que um comprador usaria.

## Fora de escopo

- Testar a storefront (F08) sob carga — o cenário bate direto no gateway/API,
  não simula navegação HTML; testar a storefront é uma extensão natural futura.
- Rodar em CI automaticamente — o script fica pronto para rodar sob demanda;
  integrar num pipeline é decisão fora deste PRD.
- Teste de carga distribuído (múltiplas máquinas gerando tráfego) — um único
  executor k6 local é suficiente para o volume deste cenário.

## Critérios de aceitação

- [ ] Exatamente `quantityTotal` pedidos confirmam — nunca mais.
- [ ] Taxa de `5xx` é zero durante todo o cenário.
- [ ] `429` e `409` aparecem (provam que F09/F07 estão agindo), mas não dominam
      a taxa de sucesso a ponto de nenhum comprador legítimo conseguir comprar.
- [ ] O relatório do k6 (thresholds) passa/falha automaticamente, sem leitura
      manual necessária para saber se a garantia de zero overselling se manteve.
