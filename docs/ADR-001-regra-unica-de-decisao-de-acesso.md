# ADR-001 – Regra única de decisão de acesso e liberação excepcional com log

- **Projeto:** Academia Vida Ativa (Grupo 8 – Os TraKinEirOs)
- **Status:** Aceita pela equipe técnica; aceite do Product Owner previsto na Sprint Review
- **Data:** 04/11/2026
- **Decisores:** Miguel de Aquila Nicoluzzi, Vinicius Oliveira Diegues, Pablo Henrique da Silva Oliveira, Guilherme Bonfim Ribeiro
- **Módulos afetados:** MÓD-04 (Gerenciamento de Acesso), MÓD-07 (Controle de Entrada); integra MÓD-01, MÓD-02, MÓD-03 e MÓD-08
- **Rastreabilidade:** PB-04, PB-07; histórias H02.004 e H02.007; RS003, RS004, RNF001, RNF002; PR #1, commit `b3a1fe9`

## 1. Contexto

O controle de entrada estava descrito em duas histórias com regras diferentes: H02.004 (capacidade, contagem de entradas e saídas, situação do plano) e H02.007 (biometria, QR Code, anti-passback de 5 minutos, liberação excepcional). Nenhuma das duas cobria o conjunto.

Além disso:

- a mensagem prevista ao aluno barrado é apenas "Dirija-se à recepção", sem informar o motivo;
- a liberação manual (celular esquecido, digital que falhou) podia ficar sem motivo e sem registro garantido;
- a regra de bloqueio corria o risco de ser reescrita em cada tela e na integração com a catraca, o que geraria retrabalho na Sprint 4 (27/11 a 11/12/2026), quando catraca e leitores serão homologados.

## 2. Decisão

1. Concentrar toda a decisão de acesso em uma função única, `decidirAcesso`, que recebe a situação do aluno (plano ativo, plano vencido, pendência financeira, última entrada, ocupação e capacidade) e devolve `permitido`, `codigo`, `motivo` e `acaoSugerida`.
2. Tela da recepção e catraca apenas consomem o resultado dessa função; nenhuma delas implementa regra de acesso própria.
3. Criar a função `liberarExcepcional`, que:
   - exige funcionário identificado e motivo escolhido na lista (`Digital falhou`, `Esqueceu o celular`, `QR Code ilegível`, `Outro (descrever)`), com descrição obrigatória para "Outro";
   - recusa a liberação quando o código de bloqueio é `PENDENCIA_FINANCEIRA`;
   - devolve um registro com aluno, funcionário, motivo, código do bloqueio e data/hora, que é gravado na tabela `log_liberacao`.
4. Ordem de avaliação da regra: pendência financeira, plano inativo, plano vencido, anti-passback (menos de 5 minutos), lotação máxima.
5. O módulo funciona no navegador (`window.VidaAtiva`) e no Node (`module.exports`), para poder ser testado sem o navegador.

## 3. Alternativas consideradas

| Alternativa | Por que foi descartada |
|---|---|
| Implementar as regras separadamente em cada tela (H02.004 e H02.007) | Duplica a regra, permite respostas diferentes para o mesmo aluno e multiplica o retrabalho na Sprint 4. |
| Colocar a regra em procedimento armazenado no MySQL | Dificulta o teste automatizado e a revisão por PR; a decisão não depende apenas de dados do banco (ex.: contador de ocupação e hora da leitura). |
| Permitir liberação excepcional também para pendência financeira, com motivo | Cria brecha de controle e contraria o objetivo do TAP de bloquear automaticamente inadimplentes. Quem regulariza o pagamento deixa de ter pendência pelo fluxo normal do MÓD-03. |
| Motivo da liberação em texto livre | Dificulta o relatório por motivo (MÓD-08) e aumenta o tempo de atendimento; por isso a lista pré-definida, com "Outro" e descrição obrigatória. |

## 4. Consequências

**Positivas**

- Uma única especificação do Controle de Entrada, que unifica H02.004 e H02.007.
- O aluno e a recepção veem sempre o motivo do bloqueio e a ação sugerida.
- Toda liberação deixa rastro por funcionário e motivo, o que sustenta o relatório de liberações do MÓD-08 e a auditoria pelo gerente.
- A regra é testável sem catraca: 12 testes automatizados cobrem aluno quite, pendência, plano vencido, plano inativo, anti-passback (antes e depois de 5 minutos), lotação máxima e os casos de recusa e de registro da liberação.

**Negativas e riscos**

- A lista de motivos pré-definidos pode não cobrir todos os casos; a opção "Outro" mitiga, mas exige descrição.
- A consulta de status em tempo real aumenta a dependência do MySQL e da rede. O modo de contingência (queda de catraca ou internet) continua no backlog.
- Aluno que já pagou, mas ainda aparece com pendência (pagamento não confirmado), continua barrado até a confirmação; a política de tolerância depende de definição do PO.
- A integração com catraca e leitores reais só será verificada na homologação da Sprint 4.

## 5. Como verificar a decisão

- Testes: `node --test decisaoAcesso.test.js` (12 testes).
- Revisão: PR #1 aprovado por integrante diferente do autor.
- Qualidade: 100% das liberações com funcionário e motivo registrados (RNF002); decisão em até 2 s em 95% das leituras e bloqueio resolvido em até 30 s (metas propostas, a confirmar com o PO).

## 6. Revisão futura

Reavaliar esta decisão se: o PO definir regra de tolerância de atraso; a catraca escolhida exigir decisão fora do navegador; ou os testes de usabilidade com a recepção mostrarem que a lista de motivos precisa mudar.
