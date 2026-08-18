# PRD — Loja de Ingressos e Produtos sob Alta Demanda (`estudo-nginx`)

> **Revisão 2** deste PRD. A primeira versão tratava o `estudo-nginx` como um
> exercício genérico de hardening de microsserviços, com o domínio de negócio do
> Laravel em aberto (ver `specs/000-.../spec.md`, seção "decisão pendente"). Esta
> revisão fecha essa lacuna: o case agora é uma **loja de ingressos e produtos**
> desenhada especificamente para ser testada sob **alta demanda e alto volume de
> requisições** — concorrência por estoque limitado é o problema central que a
> arquitetura existe para resolver, não um efeito colateral.
>
> Segue o mesmo método de `PRD_SDD_Contratos.docx`: este PRD é a fonte única da
> verdade, define as features e o que cada uma provê/consome. Cada feature tem sua
> pasta em `specs/` com `spec.md`, `plan.md` e `contract.md`.

## 1. Contexto

O repositório já tinha a forma de uma arquitetura de microsserviços — gateway
Nginx, monólito Laravel, dois serviços NestJS — mapeada na revisão anterior deste
PRD. As lacunas técnicas levantadas ali continuam válidas e seguem endereçadas
pelas mesmas features:

- `users_service` com bug no `findAll()` e sem persistência → F01.
- `orders_service` como boilerplate puro → F03 (agora expandido).
- Redis subindo ocioso → F05.
- Nomenclatura inconsistente entre pasta/serviço/container → F00.
- Sem healthcheck, sem correlation-id, sem auth interna → F02/F04/F06.

O que muda nesta revisão é o motivo de tudo isso existir. O case agora é uma loja
que vende **ingressos de eventos** (estoque por evento, tipicamente pequeno e
disputado) e **produtos** (estoque convencional) — com o objetivo explícito de
usar esse case para **testar o sistema sob alta demanda**: o cenário de uma venda
de ingresso popular recebendo milhares de tentativas de compra concorrentes
disputando um estoque fixo.

Isso muda o que é "core": controle de concorrência sobre estoque deixa de ser um
detalhe de implementação e vira o problema central que justifica o resto da
arquitetura (gateway com admissão, observabilidade, cache).

## 2. Objetivo do produto

Permitir que um comprador veja o catálogo de ingressos e produtos disponíveis e
finalize uma compra sem que o sistema venda mais do que existe em estoque — mesmo
sob milhares de tentativas concorrentes disputando o mesmo item — e ter um
cenário de teste de carga reproduzível que prova isso (ou expõe onde quebra).

## 3. Personas

- **Comprador** — usuário final que navega o catálogo (via storefront) e tenta
  comprar um ingresso ou produto; sob teste de carga, é simulado em massa pelo k6.
- **Você (mantenedor)** — estuda e demonstra padrões de controle de concorrência e
  resiliência sob carga num ambiente controlado.
- **Agente implementador** — lê este PRD + `spec.md`/`plan.md`/`contract.md` de
  cada feature e gera o código.
- **Serviço consumidor** — outro serviço da malha que depende de um contrato
  publicado (ex.: `orders_service` consumindo `catalog_service` e
  `users_service`).

## 4. Fora de escopo (por enquanto)

- Orquestração em Kubernetes ou múltiplos ambientes.
- Gateway de pagamento real — a confirmação de pedido em F03 é simulada, sem
  integrar um provedor de pagamento de verdade.
- Autenticação de usuário final completa (registro, recuperação de senha, UI de
  login) — o comprador é identificado por um `userId` já existente em F01; ver
  F08 para o que isso significa na prática.
- Fila de espera (virtual waiting room) completa com UI própria — F09 entrega
  rate limiting/admissão no gateway, não uma sala de espera com posição visível.
- Message broker dedicado (Kafka/RabbitMQ) — o controle de concorrência de
  estoque em F07 usa operações atômicas do Redis, suficiente para este escopo.
- mTLS entre containers — F06 usa token compartilhado como primeiro passo.

## 5. Métricas de sucesso

- [ ] `docker compose up` sobe todos os serviços com `healthcheck: healthy` antes
      do gateway aceitar tráfego.
- [ ] Um cenário de k6 (F10) com centenas de compradores concorrentes disputando
      um estoque limitado de ingressos nunca confirma mais pedidos do que o
      estoque configurado — zero overselling sob carga.
- [ ] O gateway responde `429`, não `5xx`, quando a taxa de requisições em
      `/api/orders/` excede o limite configurado (F09).
- [ ] A storefront (F08) completa uma compra ponta a ponta — catálogo → pedido →
      confirmação — usando só os contratos HTTP dos outros serviços, sem tabela
      de negócio própria.
- [ ] `GET /api/users/` retorna a lista real de usuários e sobrevive a restart.
- [ ] Redis é lido de fato pelos drivers de cache/sessão/fila do Laravel (F05) e
      pelo controle de estoque do catálogo (F07).
- [ ] Cada feature tem `spec.md`, `plan.md` e `contract.md` em `specs/`.

## 6. Features e dependências (provedor / consumidor)

| # | Feature | Provê | Consome |
|---|---|---|---|
| F00 | Convenção de nomenclatura de serviços e domínios | `convenção de nomenclatura` | — |
| F01 | Users Service — persistência e correção | `usuário persistido` | — |
| F02 | Gateway — convenções transversais | `convenção de borda` | — |
| F05 | Ativação do Redis | `cache/fila ativos` | — |
| F07 | Catalog Service — ingressos e produtos | `disponibilidade reservável` (reserva/confirmação/liberação atômica de estoque) | — |
| F09 | Gateway — rate limiting e admissão | `controle de admissão` | `convenção de borda` (F02) |
| F03 | Orders Service — domínio de pedidos | `pedido confirmado` vinculado a usuário e a reservas de estoque | `usuário persistido` (F01) · `convenção de borda` (F02) · `disponibilidade reservável` (F07) |
| F04 | Observabilidade e confiabilidade do compose | `ambiente observável` | `convenção de borda` (F02) |
| F06 | Autenticação entre gateway e serviços | `requisição autenticada internamente` | `usuário persistido` (F01) · `convenção de borda` (F02) |
| F08 | Storefront (Laravel) — loja e checkout | `experiência de compra` | `disponibilidade reservável` (F07) · `pedido confirmado` (F03) · `usuário persistido` (F01) |
| F10 | Teste de carga — cenário de pico de compra | `evidência de comportamento sob carga` | `pedido confirmado` (F03) · observa `controle de admissão` (F09) e `ambiente observável` (F04) |

F07 é a peça nova mais importante: sem ela, F03 não tem o que orquestrar e F10 não
tem o que estressar. É por isso que ela entra na wave 1, junto de F01/F02/F05 — não
depende de nada, e tudo o que vem depois do domínio de compra depende dela.

## 7. Ondas de execução

```
Wave 0 (recomendada primeiro — sem dependência de contrato, só de coordenação)
  F00 Convenção de nomenclatura

Wave 1 (paralelo, sem dependências)
  F01 Users: persistência e correção
  F02 Gateway: convenções transversais
  F05 Redis: ativação
  F07 Catalog: ingressos e produtos
  F09 Gateway: rate limiting e admissão      ← consome F02, mas mesma onda

Wave 2 (depende da Wave 1)
  F03 Orders: domínio de pedidos             ← consome F01 + F02 + F07
  F04 Observabilidade e confiabilidade       ← consome F02

Wave 3 (depende de Orders/Catalog já responderem de verdade)
  F06 Auth entre gateway e serviços          ← consome F01 + F02
  F08 Storefront: loja e checkout            ← consome F01 + F03 + F07

Wave 4 (capstone — depende de tudo)
  F10 Teste de carga: cenário de pico de compra
```

F09 entra na wave 1 por reaproveitar só a camada de headers de F02 (baixo
acoplamento real, mesma onda por conveniência). F08 só faz sentido na wave 3
porque uma loja que não compra de nada não tem o que demonstrar — precisa de
Orders e Catalog já respondendo. F10 fecha tudo: só existe cenário de carga
depois que há um fluxo de compra real, ponta a ponta, pra estressar. Como antes,
F00 continua sendo a exceção "de arquivo compartilhado", não de contrato — ver
`specs/000-.../plan.md`.

## 8. Estrutura de artefatos

```
PRD.md
specs/
  000-convencao-de-nomenclatura/          (F00)
  001-users-persistencia-e-correcao/      (F01)
  002-gateway-convencoes-transversais/    (F02)
  003-orders-dominio-de-pedidos/          (F03)
  004-observabilidade-e-confiabilidade/   (F04)
  005-redis-ativacao/                     (F05)
  006-auth-gateway-servicos/              (F06)
  007-catalog-ingressos-e-produtos/       (F07)
  008-storefront-loja-e-checkout/         (F08)
  009-gateway-rate-limiting-e-admissao/   (F09)
  010-teste-de-carga-pico-de-compra/      (F10)
    spec.md      ← o que será construído e por quê
    plan.md      ← passos de implementação, riscos, fora de escopo
    contract.md  ← entradas, saídas, erros e o que é provido/consumido
```
