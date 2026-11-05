/**
 * Regra única de decisão de acesso – Academia Vida Ativa (MÓD-04 / MÓD-07)
 * Unifica as regras de H02.004 e H02.007. Tela e catraca só consomem o resultado.
 * Funciona no navegador (window.VidaAtiva) e no Node (module.exports).
 */
(function (root) {
  const ANTI_PASSBACK_MS = 5 * 60 * 1000; // H02.007, regra 3

  const MOTIVOS_EXCECAO = [
    'Digital falhou',
    'Esqueceu o celular',
    'QR Code ilegível',
    'Outro (descrever)',
  ];

  const CODIGOS = {
    LIBERADO: 'LIBERADO',
    PENDENCIA_FINANCEIRA: 'PENDENCIA_FINANCEIRA',
    PLANO_VENCIDO: 'PLANO_VENCIDO',
    PLANO_INATIVO: 'PLANO_INATIVO',
    ANTI_PASSBACK: 'ANTI_PASSBACK',
    LOTACAO_MAXIMA: 'LOTACAO_MAXIMA',
  };

  function negado(codigo, motivo, acaoSugerida) {
    return { permitido: false, codigo, motivo, acaoSugerida };
  }

  /**
   * @param {object} e
   * @param {boolean} e.planoAtivo
   * @param {boolean} e.planoVencido
   * @param {boolean} e.pendenciaFinanceira
   * @param {Date|null} e.ultimaEntrada
   * @param {Date} e.agora
   * @param {number} [e.ocupacaoAtual]
   * @param {number} [e.capacidadeMaxima]
   */
  function decidirAcesso(e) {
    if (e.pendenciaFinanceira) {
      return negado(CODIGOS.PENDENCIA_FINANCEIRA,
        'Acesso Negado: Pendência Financeira.',
        'Dirija-se à recepção para regularizar o pagamento.');
    }
    if (!e.planoAtivo) {
      return negado(CODIGOS.PLANO_INATIVO,
        'Acesso Negado: plano inativo.',
        'Encaminhar à recepção para contratar ou reativar o plano.');
    }
    if (e.planoVencido) {
      return negado(CODIGOS.PLANO_VENCIDO,
        'Acesso Negado: plano vencido.',
        'Encaminhar à recepção para renovar o plano.');
    }
    if (e.ultimaEntrada && (e.agora - e.ultimaEntrada) < ANTI_PASSBACK_MS) {
      return negado(CODIGOS.ANTI_PASSBACK,
        'Acesso Negado: nova leitura em menos de 5 minutos.',
        'Aguardar alguns minutos antes de tentar novamente.');
    }
    if (e.capacidadeMaxima != null && e.ocupacaoAtual != null &&
        e.ocupacaoAtual >= e.capacidadeMaxima) {
      return negado(CODIGOS.LOTACAO_MAXIMA,
        'Acesso Negado: capacidade máxima atingida.',
        'Aguardar a saída de um aluno.');
    }
    return { permitido: true, codigo: CODIGOS.LIBERADO, motivo: 'Acesso liberado.', acaoSugerida: '' };
  }

  /**
   * Liberação excepcional: exige motivo e funcionário; nunca libera pendência financeira.
   * Retorna { ok, erro?, registro? }. O registro vira uma linha em log_liberacao.
   */
  function liberarExcepcional({ decisao, alunoId, funcionarioId, motivo, descricao, agora }) {
    if (!funcionarioId) return { ok: false, erro: 'Funcionário não identificado.' };
    if (decisao.permitido) return { ok: false, erro: 'Acesso já liberado; exceção desnecessária.' };
    if (decisao.codigo === CODIGOS.PENDENCIA_FINANCEIRA) {
      return { ok: false, erro: 'Pendência financeira não pode ser liberada por exceção.' };
    }
    if (!MOTIVOS_EXCECAO.includes(motivo)) {
      return { ok: false, erro: 'Escolha um motivo da lista antes de liberar.' };
    }
    if (motivo === 'Outro (descrever)' && !(descricao && descricao.trim())) {
      return { ok: false, erro: 'Descreva o motivo para a opção "Outro".' };
    }
    return {
      ok: true,
      registro: {
        alunoId,
        funcionarioId,
        motivo: motivo === 'Outro (descrever)' ? descricao.trim() : motivo,
        codigoBloqueio: decisao.codigo,
        dataHora: agora.toISOString(),
      },
    };
  }

  const api = { decidirAcesso, liberarExcepcional, MOTIVOS_EXCECAO, CODIGOS, ANTI_PASSBACK_MS };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.VidaAtiva = Object.assign(root.VidaAtiva || {}, api);
})(typeof window !== 'undefined' ? window : globalThis);
