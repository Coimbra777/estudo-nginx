# specs/

Artefatos SDD do `estudo-nginx`, seguindo o método de `PRD_SDD_Contratos.docx`:
o [`../PRD.md`](../PRD.md) é a fonte da verdade — define as features e o que cada
uma provê/consome. Cada pasta abaixo é uma feature, com três arquivos:

- **`spec.md`** — o que será construído, por quê, escopo e critérios de aceitação.
- **`plan.md`** — passos de implementação, na ordem, com riscos explícitos.
- **`contract.md`** — entradas, saídas, formato de erro, e o que é
  provido/consumido — a peça que evita que a feature funcione isolada mas não se
  conecte ao resto (o problema descrito na seção 3 do documento-fonte).

## Ordem de leitura recomendada

1. [`../PRD.md`](../PRD.md) — visão geral, ondas de execução, tabela de dependências.
2. A pasta da feature que for implementar — leia `spec.md` → `contract.md` →
   `plan.md` (nessa ordem: primeiro o quê, depois o combinado com o resto do
   sistema, só então o passo a passo).

## Features

| Pasta | Feature | Wave |
|---|---|---|
| [`000-convencao-de-nomenclatura`](000-convencao-de-nomenclatura/) | Convenção de nomenclatura de serviços e domínios | 0 |
| [`001-users-persistencia-e-correcao`](001-users-persistencia-e-correcao/) | Users Service: persistência e correção | 1 |
| [`002-gateway-convencoes-transversais`](002-gateway-convencoes-transversais/) | Gateway: convenções transversais | 1 |
| [`005-redis-ativacao`](005-redis-ativacao/) | Ativação do Redis | 1 |
| [`007-catalog-ingressos-e-produtos`](007-catalog-ingressos-e-produtos/) | Catalog Service: ingressos e produtos | 1 |
| [`009-gateway-rate-limiting-e-admissao`](009-gateway-rate-limiting-e-admissao/) | Gateway: rate limiting e admissão | 1 |
| [`003-orders-dominio-de-pedidos`](003-orders-dominio-de-pedidos/) | Orders Service: domínio de pedidos | 2 |
| [`004-observabilidade-e-confiabilidade`](004-observabilidade-e-confiabilidade/) | Observabilidade e confiabilidade do compose | 2 |
| [`006-auth-gateway-servicos`](006-auth-gateway-servicos/) | Autenticação entre gateway e serviços | 3 |
| [`008-storefront-loja-e-checkout`](008-storefront-loja-e-checkout/) | Storefront (Laravel): loja e checkout | 3 |
| [`010-teste-de-carga-pico-de-compra`](010-teste-de-carga-pico-de-compra/) | Teste de carga: cenário de pico de compra | 4 |

Features na mesma wave não dependem uma da outra e podem ser implementadas em
paralelo (por você ou por um agente por feature). Waves seguintes só devem começar
depois que os `contract.md` que elas consomem estiverem implementados de verdade —
não apenas escritos.

A wave 0 (F00) é uma exceção ao modelo de provedor/consumidor: nenhuma feature lê
um contrato dela. Ela vem primeiro só porque F01 e F03 citam caminhos de pasta que
F00 renomeia — uma questão de arquivo compartilhado, não de dado provido/consumido.
Ver a nota de compatibilidade em `000-convencao-de-nomenclatura/plan.md`.
