const test = require('node:test');
const assert = require('node:assert/strict');
const { decidirAcesso, liberarExcepcional, CODIGOS } = require('./decisaoAcesso');

const agora = new Date('2026-11-10T18:00:00Z');
const base = { planoAtivo: true, planoVencido: false, pendenciaFinanceira: false, ultimaEntrada: null, agora };

test('aluno quite e com plano ativo é liberado', () => {
  const r = decidirAcesso(base);
  assert.equal(r.permitido, true);
  assert.equal(r.codigo, CODIGOS.LIBERADO);
});

test('pendência financeira é negada com motivo e ação sugerida', () => {
  const r = decidirAcesso({ ...base, pendenciaFinanceira: true });
  assert.equal(r.permitido, false);
  assert.equal(r.codigo, CODIGOS.PENDENCIA_FINANCEIRA);
  assert.match(r.motivo, /Pendência Financeira/);
  assert.ok(r.acaoSugerida.length > 0);
});

test('plano vencido é negado', () => {
  assert.equal(decidirAcesso({ ...base, planoVencido: true }).codigo, CODIGOS.PLANO_VENCIDO);
});

test('plano inativo é negado', () => {
  assert.equal(decidirAcesso({ ...base, planoAtivo: false }).codigo, CODIGOS.PLANO_INATIVO);
});

test('anti-passback: nova leitura em menos de 5 minutos é negada', () => {
  const r = decidirAcesso({ ...base, ultimaEntrada: new Date(agora - 2 * 60 * 1000) });
  assert.equal(r.codigo, CODIGOS.ANTI_PASSBACK);
});

test('anti-passback: leitura após 5 minutos é liberada', () => {
  const r = decidirAcesso({ ...base, ultimaEntrada: new Date(agora - 6 * 60 * 1000) });
  assert.equal(r.permitido, true);
});

test('lotação máxima bloqueia novas entradas', () => {
  const r = decidirAcesso({ ...base, ocupacaoAtual: 80, capacidadeMaxima: 80 });
  assert.equal(r.codigo, CODIGOS.LOTACAO_MAXIMA);
});

test('liberação excepcional sem motivo é recusada', () => {
  const d = decidirAcesso({ ...base, planoVencido: true });
  const r = liberarExcepcional({ decisao: d, alunoId: 1, funcionarioId: 7, motivo: '', agora });
  assert.equal(r.ok, false);
});

test('liberação excepcional sem funcionário é recusada', () => {
  const d = decidirAcesso({ ...base, ultimaEntrada: new Date(agora - 60000) });
  const r = liberarExcepcional({ decisao: d, alunoId: 1, funcionarioId: null, motivo: 'Digital falhou', agora });
  assert.equal(r.ok, false);
});

test('pendência financeira nunca é liberada por exceção', () => {
  const d = decidirAcesso({ ...base, pendenciaFinanceira: true });
  const r = liberarExcepcional({ decisao: d, alunoId: 1, funcionarioId: 7, motivo: 'Esqueceu o celular', agora });
  assert.equal(r.ok, false);
  assert.match(r.erro, /Pendência financeira/);
});

test('liberação válida gera registro com aluno, funcionário, motivo e data/hora', () => {
  const d = decidirAcesso({ ...base, ultimaEntrada: new Date(agora - 60000) });
  const r = liberarExcepcional({ decisao: d, alunoId: 12, funcionarioId: 7, motivo: 'Digital falhou', agora });
  assert.equal(r.ok, true);
  assert.deepEqual(Object.keys(r.registro).sort(),
    ['alunoId', 'codigoBloqueio', 'dataHora', 'funcionarioId', 'motivo']);
  assert.equal(r.registro.motivo, 'Digital falhou');
});

test('motivo "Outro" exige descrição', () => {
  const d = decidirAcesso({ ...base, planoVencido: true });
  assert.equal(liberarExcepcional({ decisao: d, alunoId: 1, funcionarioId: 7, motivo: 'Outro (descrever)', descricao: '  ', agora }).ok, false);
  assert.equal(liberarExcepcional({ decisao: d, alunoId: 1, funcionarioId: 7, motivo: 'Outro (descrever)', descricao: 'Plano em renovação', agora }).ok, true);
});
