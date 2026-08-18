# F10 — Contrato

## Provê

Um relatório (saída do k6 + checagem de contagem pós-teste) que confirma ou
refuta as garantias de F07 (zero overselling) e F09 (admissão sob pico) sob
carga real. Não é uma API — é uma evidência.

## Consome

- **F03 — `POST /api/orders/`** via gateway, o alvo principal do cenário.
- Observa (sem modificar) **F09** (taxa de `429`) e **F04** (logs
  correlacionados por `X-Correlation-Id` durante o pico, se for preciso
  investigar uma falha).

## Consumido por

Ninguém — é a última wave. O "consumidor" é você, lendo o relatório.
