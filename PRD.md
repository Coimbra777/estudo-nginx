# PRD — Evolução do `estudo-nginx` para Arquitetura de Microsserviços

> Segue o método descrito em `PRD_SDD_Contratos.docx`: este PRD é a fonte única da
> verdade, define as features e — o mais importante — **o que cada uma provê e
> consome**, para que dependências fiquem explícitas e o que pode rodar em paralelo
> fique claro antes de qualquer linha de código. Cada feature abaixo tem sua pasta em
> `specs/` com `spec.md`, `plan.md` e `contract.md`.

## 1. Contexto

O repositório já tem a forma de uma arquitetura de microsserviços — um gateway
Nginx (`docker/nginx/default.conf`) na frente de um monólito Laravel e dois
serviços NestJS (`users_service`, `orders_service`) — mas hoje é majoritariamente
esqueleto:

- `users_service` tem CRUD completo de rotas, mas guarda tudo em array em memória
  (`nestjs-boilerplate-api/src/users/users.service.ts`) e `findAll()` tem um bug:
  sempre retorna a string fixa `'User list'` (linha 40) em vez do array real (o
  `return this.users` está comentado na linha 41).
- `orders_service` (`projeto-nest-1/`) é o boilerplate puro do Nest CLI — só existe
  `AppController`/`AppService`, sem nenhum módulo de pedidos, mesmo já roteado em
  `/api/orders/`.
- `laravel` é o esqueleto padrão do `laravel/laravel`, sem rotas de negócio.
- `redis_shared` sobe no compose, mas `CACHE_DRIVER`, `SESSION_DRIVER` e
  `QUEUE_CONNECTION` continuam em `file`/`sync` no `.env` do Laravel — Redis existe,
  mas nenhum driver o lê.
- Nenhum serviço tem `healthcheck`; `depends_on` só espera o container iniciar, não
  ficar pronto.
- O Nginx só faz `proxy_pass`/`fastcgi_pass` puro: sem correlation-id, sem timeout
  explícito, sem formato de erro padronizado para upstream fora do ar.
- Ambos os serviços Node declaram `PORT` via env no compose, mas `main.ts` ignora a
  variável e usa a porta hardcoded (`app.listen(3001, ...)` / `app.listen(3000, ...)`)
  — outro exemplo do padrão "configurado, mas não conectado" que aparece com o Redis.

Este PRD trata essas lacunas não como bugs isolados, mas como o roteiro para
transformar o laboratório em uma arquitetura de microsserviços de verdade: serviços
donos do próprio domínio e dos próprios dados, comunicação entre serviços via
contrato explícito, e um gateway que é borda de segurança/observabilidade — não só
um proxy.

## 2. Objetivo do produto

Cada serviço atrás do gateway deve (a) persistir seus próprios dados, (b) expor um
contrato estável para quem consome, e (c) se comunicar com os demais serviços
apenas através desses contratos — nunca acoplado à implementação interna de outro
serviço. O gateway deixa de ser um proxy burro e passa a impor convenções comuns
(correlation-id, formato de erro, e eventualmente autenticação interna) a tudo que
passa por ele.

## 3. Personas

- **Você (mantenedor)** — estuda e demonstra padrões reais de microsserviços num
  ambiente controlado.
- **Agente implementador** — lê este PRD + `spec.md` + `plan.md` + `contract.md` de
  cada feature e gera o código, conforme o fluxo descrito em `PRD_SDD_Contratos.docx`.
- **Serviço consumidor** — outro serviço da malha (ex.: `orders_service` consumindo
  `users_service`) que depende do contrato publicado, não da implementação interna.

## 4. Fora de escopo (por enquanto)

- Orquestração em Kubernetes ou múltiplos ambientes (stage/prod separados).
- Migração funcional do Laravel para os microsserviços (o monólito permanece; só
  passa a seguir as mesmas convenções de borda do gateway).
- Autenticação de usuário final (login, hash de senha, sessão de cliente externo).
- Message broker dedicado (Kafka/RabbitMQ) — Redis pub/sub, se necessário, é
  suficiente para o estágio atual.
- mTLS entre containers — a F06 propõe um token compartilhado como primeiro passo,
  não a solução final.

## 5. Métricas de sucesso

- [ ] `docker compose up` sobe todos os serviços com `healthcheck: healthy` antes do
      Nginx aceitar tráfego.
- [ ] `GET /api/users/` retorna a lista real de usuários e os dados sobrevivem a um
      `docker compose restart users_service`.
- [ ] `POST /api/orders/` só cria um pedido se o `userId` existir no Users Service —
      primeiro contrato síncrono real entre dois serviços do projeto.
- [ ] Toda requisição via gateway carrega um `X-Correlation-Id` visível nos logs dos
      serviços de destino.
- [ ] Redis é efetivamente lido pelos drivers de cache/sessão/fila do Laravel.
- [ ] Cada feature abaixo tem `spec.md`, `plan.md` e `contract.md` em `specs/`.

## 6. Features e dependências (provedor / consumidor)

| # | Feature | Provê | Consome |
|---|---|---|---|
| F01 | Users Service — persistência e correção | `usuário persistido` (dados com id estável + `GET /users/:id/exists`) | — |
| F02 | Gateway — convenções transversais | `convenção de borda` (correlation-id, timeout, erro padronizado) | — |
| F05 | Ativação do Redis | `cache/fila ativos` no Laravel | — |
| F03 | Orders Service — domínio de pedidos | `pedido persistido` vinculado a usuário validado | `usuário persistido` (F01) · `convenção de borda` (F02) |
| F04 | Observabilidade e confiabilidade do compose | `ambiente observável` (healthcheck, logs correlacionados) | `convenção de borda` (F02) |
| F06 | Autenticação entre gateway e serviços | `requisição autenticada internamente` | `usuário persistido` (F01) · `convenção de borda` (F02) |

Isso é exatamente o diagnóstico do capítulo 3/4 do documento-fonte aplicado aqui:
sem esta tabela, seria fácil implementar F03 (orders) sem pensar em como ele valida
o `userId`, e o resultado seria um "Orders funciona, mas aceita qualquer id" — a
mesma classe de problema do exemplo "F03 Criar tarefa funciona, mas a tarefa não
aparece no F04 Quadro Kanban".

## 7. Ondas de execução

```
Wave 1 (paralelo, sem dependências)
  F01 Users: persistência e correção
  F02 Gateway: convenções transversais
  F05 Redis: ativação

Wave 2 (depende da Wave 1)
  F03 Orders: domínio de pedidos      ← consome F01 + F02
  F04 Observabilidade e confiabilidade ← consome F02

Wave 3 (fecha o ciclo de segurança)
  F06 Auth entre gateway e serviços   ← consome F01 + F02
```

F01, F02 e F05 não dependem de nada entre si e podem ser implementadas em paralelo
(por você, por um agente, ou por duas pessoas). F03 e F04 só fazem sentido depois
que os contratos que consomem existem. F06 fecha o ciclo por último porque protege
dados e rotas que precisam já estar estáveis.

## 8. Estrutura de artefatos

```
PRD.md                                          ← este arquivo
specs/
  001-users-persistencia-e-correcao/    (F01)
  002-gateway-convencoes-transversais/  (F02)
  003-orders-dominio-de-pedidos/        (F03)
  004-observabilidade-e-confiabilidade/ (F04)
  005-redis-ativacao/                   (F05)
  006-auth-gateway-servicos/            (F06)
    spec.md      ← o que será construído e por quê
    plan.md      ← passos de implementação, riscos, fora de escopo
    contract.md  ← entradas, saídas, erros e o que é provido/consumido
```
