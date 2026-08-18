# F10 — Plano de implementação

## Pré-requisitos

Praticamente tudo: F01 (usuários para simular), F03 (fluxo de pedido), F07
(estoque a disputar), F09 (para observar o rate limit agindo), F04 (para
correlacionar o que aconteceu nos logs durante o pico).

## Passos

1. `loadtest/seed.js` — script que cria os 1000 usuários via F01 e o
   `CatalogItem` com `quantityTotal=100` via F07, salvando os ids num arquivo
   (`loadtest/seed-data.json`) que o cenário principal lê.
2. `loadtest/purchase-peak.js`:
   ```js
   import http from 'k6/http';
   import { check } from 'k6';

   export const options = {
     stages: [
       { duration: '30s', target: 500 },
       { duration: '60s', target: 500 },
       { duration: '10s', target: 0 },
     ],
     thresholds: {
       'http_req_failed{status:5xx}': ['rate==0'],
       'http_req_duration': ['p(95)<800'],
     },
   };

   export default function () {
     const user = /* escolhe um userId do seed-data.json */;
     const res = http.post('http://localhost:8080/api/orders/', JSON.stringify({
       userId: user.id,
       items: [{ catalogItemId: TICKET_ID, quantity: 1 }],
     }), { headers: { 'Content-Type': 'application/json' } });
     check(res, {
       'não é 5xx': (r) => r.status < 500,
     });
   }
   ```
3. Pós-processamento: script pequeno que consulta
   `GET /api/orders/?status=confirmed` (ou uma contagem direta no
   `orders_db`/`catalog_db`) e compara com `quantityTotal` — essa checagem
   final é o que realmente prova "zero overselling"; os `thresholds` do k6
   cobrem latência/erro, não a contagem de negócio.
4. Adicionar um alvo no `Makefile` (`make loadtest`) rodando
   `k6 run loadtest/purchase-peak.js` depois do seed.
5. Documentar em `loadtest/README.md` como interpretar o relatório do k6 e onde
   olhar os logs correlacionados (F04) se algo passar de 5xx.

## Riscos

- Rodar 500 VUs localmente compete por CPU com os próprios containers sendo
  testados (mesma máquina) — os números absolutos de latência não são
  representativos de produção; o que importa aqui é a contagem de negócio
  (overselling ou não), não o valor exato de p95.
- Se F09 (rate limit) estiver calibrado baixo demais, o teste pode nunca
  conseguir gerar 500 tentativas simultâneas reais no backend — ajustar
  `rate`/`burst` de F09 usando o resultado deste teste é esperado (é uma
  relação de mão dupla, não só F10 dependendo de F09).

## Fora de escopo desta feature

Ver `spec.md`.
