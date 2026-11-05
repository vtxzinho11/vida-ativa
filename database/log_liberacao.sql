-- Log de liberações excepcionais (MÓD-04/07). Ajustar nomes de tabelas referenciadas ao esquema real.
CREATE TABLE IF NOT EXISTS log_liberacao (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  aluno_id         INT          NOT NULL,
  funcionario_id   INT          NOT NULL,
  motivo           VARCHAR(255) NOT NULL,
  codigo_bloqueio  VARCHAR(30)  NOT NULL,
  data_hora        DATETIME     NOT NULL,
  FOREIGN KEY (aluno_id)       REFERENCES cliente(id),
  FOREIGN KEY (funcionario_id) REFERENCES funcionario(id)
);

-- Relatório de liberações por funcionário e motivo (MÓD-08)
SELECT f.nome AS funcionario, l.motivo, COUNT(*) AS total
FROM log_liberacao l
JOIN funcionario f ON f.id = l.funcionario_id
GROUP BY f.nome, l.motivo
ORDER BY total DESC;
