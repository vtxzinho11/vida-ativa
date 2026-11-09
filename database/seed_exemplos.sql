-- =====================================================================
-- Vida Ativa — dados de EXEMPLO em volume (todos fictícios).
--
-- Ordem:  schema.sql  ->  (seed.sql, opcional)  ->  este arquivo.
-- Pode rodar mais de uma vez sem duplicar linhas.
--
-- Senha de TODOS os usuários abaixo: 123456   (troque antes de usar de verdade!)
--
-- O que este arquivo cria (além do que já existe no seed.sql):
--   9 usuários de equipe (4 funcionários + 5 professores; 1 de cada inativo)
--  24 alunos (Básico / Plus / Premium; CONVENCIONAL e TOTALPASS; 3 em atraso, 2 inativos)
--  ~134 pagamentos (até 6 meses de histórico por aluno, status variados)
--  18 fichas de treino (ATIVA, RASCUNHO e INATIVA) com treinos e exercícios
--  28 avaliações físicas (com evolução ao longo do tempo)
--
-- Logins para testar:  camila.rodrigues (funcionário) · rafael.mendes (professor)
--                      ana.souza / bruno.oliveira / ... (alunos)
-- Os CPFs são gerados aleatoriamente (dígitos verificadores válidos) e não
-- pertencem a pessoas reais de propósito.
-- =====================================================================
USE vida_ativa;
SET NAMES utf8mb4;

-- hash PBKDF2 (com salt) da senha 123456 — o mesmo do seed.sql
SET @senha := 'pbkdf2$120000$bVfzWX/sFvm1HfpeGf7Nlg==$WK+ITfb3bP00cYF9Ua7rkvj3RglDWZvmD5tuX6oBnxc=';

DROP TEMPORARY TABLE IF EXISTS tmp_equipe;
DROP TEMPORARY TABLE IF EXISTS tmp_alunos;
DROP TEMPORARY TABLE IF EXISTS tmp_fichas;
DROP TEMPORARY TABLE IF EXISTS tmp_treino_tpl;
DROP TEMPORARY TABLE IF EXISTS tmp_ex_tpl;
DROP TEMPORARY TABLE IF EXISTS tmp_aval;

-- =====================================================================
-- 1) EQUIPE (funcionários e professores)
-- =====================================================================
CREATE TEMPORARY TABLE tmp_equipe (
    username VARCHAR(60), nome VARCHAR(120), email VARCHAR(150),
    perfil VARCHAR(20), cargo VARCHAR(120), ativo TINYINT
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tmp_equipe VALUES
('camila.rodrigues','Camila Rodrigues','camila.rodrigues@vidaativa.local','FUNCIONARIO','Recepcionista',1),
('marcos.lima','Marcos Vinícius Lima','marcos.lima@vidaativa.local','FUNCIONARIO','Consultor Comercial',1),
('patricia.almeida','Patrícia Almeida','patricia.almeida@vidaativa.local','FUNCIONARIO','Auxiliar Financeiro',1),
('rogerio.teixeira','Rogério Teixeira','rogerio.teixeira@vidaativa.local','FUNCIONARIO','Recepcionista',0),
('rafael.mendes','Rafael Mendes','rafael.mendes@vidaativa.local','PROFESSOR','Musculação e Hipertrofia',1),
('juliana.costa','Juliana Costa','juliana.costa@vidaativa.local','PROFESSOR','Funcional e Emagrecimento',1),
('thiago.barbosa','Thiago Barbosa','thiago.barbosa@vidaativa.local','PROFESSOR','Força e Powerlifting',1),
('larissa.nogueira','Larissa Nogueira','larissa.nogueira@vidaativa.local','PROFESSOR','Avaliação Física e Saúde',1),
('eduardo.pires','Eduardo Pires','eduardo.pires@vidaativa.local','PROFESSOR','Spinning',0);

INSERT INTO usuarios(nome,email,username,senha_hash,perfil,ativo)
SELECT nome,email,username,@senha,perfil,ativo FROM tmp_equipe
ON DUPLICATE KEY UPDATE nome=VALUES(nome);

INSERT INTO funcionarios(usuario_id,cargo,ativo)
SELECT u.id, t.cargo, t.ativo
FROM tmp_equipe t JOIN usuarios u ON u.username=t.username
WHERE t.perfil='FUNCIONARIO'
ON DUPLICATE KEY UPDATE cargo=VALUES(cargo);

INSERT INTO professores(usuario_id,especialidade,ativo)
SELECT u.id, t.cargo, t.ativo
FROM tmp_equipe t JOIN usuarios u ON u.username=t.username
WHERE t.perfil='PROFESSOR'
ON DUPLICATE KEY UPDATE especialidade=VALUES(especialidade);


-- =====================================================================
-- 2) ALUNOS
-- sit: EM_DIA = mensalidades em dia | ATRASO = inadimplente | INATIVO = matrícula cancelada
-- dia_venc = dia do mês em que a mensalidade vence
-- =====================================================================
CREATE TEMPORARY TABLE tmp_alunos (
    username VARCHAR(60), nome VARCHAR(120), email VARCHAR(150),
    documento VARCHAR(30), telefone VARCHAR(30), nascimento DATE, inicio DATE,
    plano VARCHAR(50), tipo VARCHAR(20), forma VARCHAR(20),
    dia_venc INT, sit VARCHAR(10), obs TEXT, ativo TINYINT
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tmp_alunos
(username,nome,email,documento,telefone,nascimento,inicio,plano,tipo,forma,dia_venc,sit,obs,ativo) VALUES
('ana.souza','Ana Carolina Souza','ana.souza@email.com','104.332.181-00','(11) 98418-7912','1995-03-14','2025-02-10','Plus','CONVENCIONAL','PIX',5,'EM_DIA','Foco em hipertrofia de glúteos.',1),
('bruno.oliveira','Bruno Oliveira Santos','bruno.oliveira@gmail.com','001.338.908-48','(11) 96814-9928','1989-11-02','2024-08-19','Premium','CONVENCIONAL','CARTAO',10,'EM_DIA','Treina cedo, antes do trabalho (6h).',1),
('carla.ferreira','Carla Ferreira Lima','carla.ferreira@outlook.com','637.940.265-94','(11) 97138-3547','1992-07-25','2025-06-03','Básico','CONVENCIONAL','BOLETO',15,'ATRASO',NULL,1),
('diego.martins','Diego Martins Rocha','diego.martins@email.com','351.161.559-35','(11) 97083-1711','2001-01-30','2026-01-12','Plus','TOTALPASS','CARTAO',12,'EM_DIA','Cliente TotalPass.',1),
('elisa.barros','Elisa Barros Campos','elisa.barros@gmail.com','781.618.495-60','(11) 98364-4150','1998-09-18','2025-10-05','Premium','CONVENCIONAL','PIX',8,'EM_DIA','Preparação para meia maratona; reforço de core.',1),
('fernando.alves','Fernando Alves Pinto','fernando.alves@email.com','103.413.164-82','(11) 97857-6977','1978-04-09','2023-05-22','Plus','CONVENCIONAL','DINHEIRO',20,'EM_DIA','Acompanhamento de pressão arterial; atestado médico em dia.',1),
('gabriela.nunes','Gabriela Nunes Duarte','gabriela.nunes@outlook.com','255.341.928-79','(11) 98986-5010','2003-12-21','2026-06-15','Básico','TOTALPASS','CARTAO',12,'EM_DIA','Cliente TotalPass.',1),
('henrique.castro','Henrique Castro Machado','henrique.castro@gmail.com','276.483.503-51','(11) 99366-1525','1985-06-07','2024-03-04','Premium','CONVENCIONAL','CARTAO',1,'EM_DIA','Powerlifting amador; compete em 2027.',1),
('isabela.ramos','Isabela Ramos Freitas','isabela.ramos@email.com','564.139.537-48','(11) 97620-8517','1999-02-11','2025-09-01','Plus','CONVENCIONAL','PIX',10,'EM_DIA',NULL,1),
('joao.pereira','João Pedro Pereira','joao.pereira@gmail.com','242.388.496-63','(11) 99677-7543','2004-08-29','2026-03-02','Básico','CONVENCIONAL','PIX',7,'EM_DIA',NULL,1),
('karina.dias','Karina Dias Moreira','karina.dias@outlook.com','532.871.012-69','(11) 98570-3621','1990-10-05','2024-11-11','Plus','CONVENCIONAL','BOLETO',25,'ATRASO','Mensalidade em atraso; recepção já entrou em contato.',1),
('leandro.gomes','Leandro Gomes Carvalho','leandro.gomes@email.com','691.669.784-91','(11) 99977-1188','1982-05-16','2023-09-18','Premium','CONVENCIONAL','PIX',3,'EM_DIA','Objetivo: perda de gordura e condicionamento.',1),
('mariana.lopes','Mariana Lopes Siqueira','mariana.lopes@gmail.com','184.514.627-15','(11) 96013-5315','1996-12-03','2025-04-07','Plus','TOTALPASS','CARTAO',18,'EM_DIA','Cliente TotalPass.',1),
('nathan.ribeiro','Nathan Ribeiro Costa','nathan.ribeiro@email.com','828.148.932-46','(11) 97531-3646','2000-03-22','2025-12-01','Básico','CONVENCIONAL','DINHEIRO',6,'EM_DIA',NULL,1),
('olivia.cardoso','Olívia Cardoso Prado','olivia.cardoso@email.com','880.957.015-48','(11) 99599-6038','1975-09-09','2022-02-14','Plus','CONVENCIONAL','PIX',15,'EM_DIA','Foco em mobilidade e saúde articular.',1),
('paulo.vieira','Paulo Vieira Neto','paulo.vieira@outlook.com','303.911.718-10','(11) 99136-3060','1993-01-17','2025-07-21','Básico','CONVENCIONAL','BOLETO',20,'ATRASO',NULL,1),
('rafaela.matos','Rafaela Matos Teles','rafaela.matos@gmail.com','278.248.963-15','(11) 99804-9835','1997-06-28','2024-10-07','Premium','CONVENCIONAL','CARTAO',9,'EM_DIA','Objetivo: emagrecimento em 90 dias.',1),
('samuel.araujo','Samuel Araújo Batista','samuel.araujo@email.com','346.578.713-74','(11) 96920-2049','1988-08-13','2024-01-15','Plus','TOTALPASS','CARTAO',11,'EM_DIA','Cliente TotalPass.',1),
('tatiane.freire','Tatiane Freire Mota','tatiane.freire@gmail.com','509.839.301-98','(11) 98899-1964','1994-11-26','2025-03-17','Básico','CONVENCIONAL','PIX',22,'EM_DIA',NULL,1),
('vinicius.teixeira','Vinícius Teixeira Lima','vinicius.teixeira@email.com','310.518.347-75','(11) 96877-9834','2002-04-04','2025-05-12','Plus','CONVENCIONAL','PIX',14,'EM_DIA',NULL,1),
('yasmin.cavalcante','Yasmin Cavalcante Reis','yasmin.cavalcante@outlook.com','299.737.631-90','(11) 96397-8062','2005-07-19',DATE_SUB(CURDATE(), INTERVAL 20 DAY),'Plus','CONVENCIONAL','PIX',28,'EM_DIA','Aluna nova; matrícula recente.',1),
('wagner.santos','Wagner Santos Filho','wagner.santos@email.com','566.701.065-80','(11) 99279-2790','1970-02-27','2021-08-09','Básico','CONVENCIONAL','DINHEIRO',4,'INATIVO','Matrícula cancelada a pedido do aluno.',0),
('zilda.moura','Zilda Moura Andrade','zilda.moura@email.com','333.872.624-42','(11) 97894-5092','1968-10-31','2023-01-23','Plus','CONVENCIONAL','BOLETO',13,'INATIVO','Mudou de cidade; matrícula encerrada.',0),
('augusto.lima','Augusto Lima Brandão','augusto.lima@gmail.com','178.108.013-50','(11) 96681-7658','1991-05-05',DATE_SUB(CURDATE(), INTERVAL 8 DAY),'Premium','CONVENCIONAL','CARTAO',9,'EM_DIA','Matrícula recente.',1);

INSERT INTO usuarios(nome,email,username,senha_hash,perfil,ativo)
SELECT nome,email,username,@senha,'ALUNO',ativo FROM tmp_alunos
ON DUPLICATE KEY UPDATE nome=VALUES(nome);

-- vencimento do aluno: próximo vencimento (em dia), último vencimento (atraso) ou NULL (inativo)
INSERT INTO alunos(usuario_id,documento,telefone,data_nascimento,data_inicio,plano_id,tipo_cliente,forma_pagamento,vencimento,observacoes,ativo)
SELECT u.id, ta.documento, ta.telefone, ta.nascimento, ta.inicio, p.id, ta.tipo, ta.forma,
  CASE ta.sit
    WHEN 'INATIVO' THEN NULL
    WHEN 'ATRASO'  THEN DATE_ADD(DATE_ADD(CAST(DATE_FORMAT(CURDATE(),'%Y-%m-01') AS DATE),
                          INTERVAL IF(ta.dia_venc < DAY(CURDATE()),0,-1) MONTH), INTERVAL ta.dia_venc-1 DAY)
    ELSE                DATE_ADD(DATE_ADD(CAST(DATE_FORMAT(CURDATE(),'%Y-%m-01') AS DATE),
                          INTERVAL IF(ta.dia_venc >= DAY(CURDATE()),0,1) MONTH), INTERVAL ta.dia_venc-1 DAY)
  END,
  ta.obs, ta.ativo
FROM tmp_alunos ta
JOIN usuarios u ON u.username = ta.username
JOIN planos   p ON p.nome = ta.plano
ON DUPLICATE KEY UPDATE telefone=VALUES(telefone), documento=VALUES(documento);

-- =====================================================================
-- 3) PAGAMENTOS — até 6 meses de histórico por aluno (mês atual + 5 anteriores),
--    nunca antes da data de início do aluno. Um por aluno por mês (referencia).
-- =====================================================================
INSERT INTO pagamentos(aluno_id,data_pagamento,valor,forma_pagamento,status,vencimento,referencia)
SELECT x.aluno_id,
       CASE WHEN x.status='PAGO' THEN DATE_SUB(x.venc, INTERVAL MOD(x.aluno_id + x.n, 3) DAY) END,
       x.valor, x.forma, x.status, x.venc, x.ref
FROM (
    SELECT b.*,
      CASE
        WHEN b.sit='INATIVO' THEN IF(b.n>=2,'PAGO','CANCELADO')
        WHEN b.sit='ATRASO'  THEN CASE WHEN b.n=0 THEN IF(b.venc<CURDATE(),'ATRASADO','PENDENTE')
                                       WHEN b.n=1 THEN 'ATRASADO'
                                       ELSE 'PAGO' END
        ELSE IF(b.n=0 AND b.venc>CURDATE(),'PENDENTE','PAGO')
      END AS status
    FROM (
        SELECT a.id AS aluno_id, m.n, ta.sit, p.valor_mensal AS valor, a.forma_pagamento AS forma,
               DATE_ADD(CAST(DATE_SUB(CAST(DATE_FORMAT(CURDATE(),'%Y-%m-01') AS DATE), INTERVAL m.n MONTH) AS DATE),
                        INTERVAL ta.dia_venc-1 DAY) AS venc,
               DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL m.n MONTH),'%Y-%m') AS ref,
               a.data_inicio
        FROM tmp_alunos ta
        JOIN usuarios u ON u.username = ta.username
        JOIN alunos   a ON a.usuario_id = u.id
        JOIN planos   p ON p.id = a.plano_id
        JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2
              UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) m
    ) b
    WHERE b.venc >= b.data_inicio
) x
ON DUPLICATE KEY UPDATE valor=VALUES(valor);


-- =====================================================================
-- 4) FICHAS DE TREINO, TREINOS E EXERCÍCIOS
-- Cada ficha usa um "modelo" (tpl): ABC, FULLBODY, EMAGRECIMENTO, GLUTEOS, UPPER_LOWER
-- =====================================================================
CREATE TEMPORARY TABLE tmp_fichas (
    aluno_user VARCHAR(60), prof_user VARCHAR(60), nome VARCHAR(120), objetivo VARCHAR(120),
    freq INT, ini_dias INT, rev_dias INT, status VARCHAR(10), tpl VARCHAR(20), obs TEXT
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tmp_fichas VALUES
('ana.souza','rafael.mendes','Glúteos e Posterior','Hipertrofia',4,30,60,'ATIVA','GLUTEOS','Priorizar execução e amplitude no hip thrust.'),
('ana.souza','rafael.mendes','Adaptação Full Body','Adaptação',3,240,-120,'INATIVA','FULLBODY','Ficha anterior, substituída.'),
('bruno.oliveira','thiago.barbosa','Upper/Lower Força','Força e hipertrofia',4,45,45,'ATIVA','UPPER_LOWER','Aquecimento articular de 8 min antes de cada treino.'),
('diego.martins','rafael.mendes','Full Body Iniciante','Adaptação',3,25,35,'ATIVA','FULLBODY','Aumentar carga só após 2 semanas estáveis.'),
('elisa.barros','juliana.costa','Circuito Funcional','Condicionamento para corrida',3,20,70,'ATIVA','EMAGRECIMENTO','Alongar bem após os treinos.'),
('fernando.alves','larissa.nogueira','Full Body Adaptação','Saúde e qualidade de vida',3,35,55,'ATIVA','FULLBODY','Evitar apneia nos esforços; monitorar pressão.'),
('henrique.castro','thiago.barbosa','Powerlifting — Base','Força máxima',3,50,40,'ATIVA','ABC','Registrar cargas máximas a cada 4 semanas.'),
('isabela.ramos','juliana.costa','Circuito Emagrecimento','Emagrecimento',4,28,62,'ATIVA','EMAGRECIMENTO','Hidratação constante.'),
('karina.dias','rafael.mendes','Full Body Tonificação','Tonificação',3,150,-60,'INATIVA','FULLBODY','Ficha encerrada; aluna em atraso.'),
('leandro.gomes','thiago.barbosa','Hipertrofia ABC','Hipertrofia e perda de gordura',3,40,50,'ATIVA','ABC','Combinar com cardio leve ao final.'),
('mariana.lopes','juliana.costa','Glúteos 4x','Hipertrofia de glúteos',4,18,72,'ATIVA','GLUTEOS',NULL),
('olivia.cardoso','larissa.nogueira','Mobilidade e Força Leve','Saúde articular',3,60,30,'ATIVA','FULLBODY','Cargas moderadas, foco em amplitude.'),
('rafaela.matos','juliana.costa','Emagrecimento 90 dias','Emagrecimento',4,55,35,'ATIVA','EMAGRECIMENTO','Reavaliar medidas a cada 30 dias.'),
('samuel.araujo','thiago.barbosa','Hipertrofia ABC','Hipertrofia',3,33,57,'ATIVA','ABC',NULL),
('vinicius.teixeira','rafael.mendes','Upper/Lower Hipertrofia','Hipertrofia',4,22,68,'ATIVA','UPPER_LOWER',NULL),
('yasmin.cavalcante','larissa.nogueira','Adaptação Inicial','Adaptação',3,2,88,'RASCUNHO','FULLBODY','Rascunho — aguardando revisão do professor.'),
('augusto.lima','thiago.barbosa','Avaliação e Hipertrofia','Hipertrofia',4,1,89,'RASCUNHO','UPPER_LOWER','Rascunho — ajustar após avaliação inicial.'),
('zilda.moura','larissa.nogueira','Full Body Leve','Saúde e mobilidade',2,300,-200,'INATIVA','FULLBODY','Aluna com matrícula encerrada.');

CREATE TEMPORARY TABLE tmp_treino_tpl (
    tpl VARCHAR(20), ordem INT, nome VARCHAR(80), dia_semana VARCHAR(20), descricao VARCHAR(255)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tmp_treino_tpl VALUES
('ABC',1,'Treino A — Peito e tríceps','Segunda-feira','Foco em peitoral com apoio de tríceps'),
('ABC',2,'Treino B — Costas e bíceps','Quarta-feira','Foco em dorsais com apoio de bíceps'),
('ABC',3,'Treino C — Pernas e ombros','Sexta-feira','Membros inferiores e deltoides'),
('FULLBODY',1,'Full Body A','Segunda-feira','Corpo inteiro — ênfase em empurrar e agachar'),
('FULLBODY',2,'Full Body B','Quarta-feira','Corpo inteiro — ênfase em puxar e pernas'),
('FULLBODY',3,'Full Body C','Sexta-feira','Corpo inteiro — posterior e estabilização'),
('EMAGRECIMENTO',1,'Circuito 1 — Força e metabólico','Terça-feira','Circuito de alta densidade'),
('EMAGRECIMENTO',2,'Cardio e core','Quinta-feira','Intervalado + abdômen'),
('EMAGRECIMENTO',3,'Circuito 2 — Corpo inteiro','Sábado','Circuito com máquinas e peso corporal'),
('GLUTEOS',1,'Treino A — Glúteos e posterior','Segunda-feira','Ênfase em glúteo máximo e isquiotibiais'),
('GLUTEOS',2,'Treino B — Superiores e core','Quarta-feira','Membros superiores e abdômen'),
('GLUTEOS',3,'Treino C — Glúteos e quadríceps','Sexta-feira','Glúteo médio, quadríceps e abdutores'),
('UPPER_LOWER',1,'Upper A — Força','Segunda-feira','Superiores com cargas altas'),
('UPPER_LOWER',2,'Lower A — Força','Terça-feira','Inferiores com cargas altas'),
('UPPER_LOWER',3,'Upper B — Volume','Quinta-feira','Superiores com mais volume'),
('UPPER_LOWER',4,'Lower B — Volume','Sexta-feira','Inferiores com mais volume');

CREATE TEMPORARY TABLE tmp_ex_tpl (
    tpl VARCHAR(20), treino VARCHAR(80), ordem INT, nome VARCHAR(120), grupo VARCHAR(80),
    series INT, repeticoes VARCHAR(30), carga VARCHAR(30), descanso VARCHAR(30), obs VARCHAR(255)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tmp_ex_tpl VALUES
('ABC','Treino A — Peito e tríceps',1,'Supino reto','Peito',4,'8-10','60 kg','90 s','Cadência controlada'),
('ABC','Treino A — Peito e tríceps',2,'Supino inclinado com halteres','Peito',3,'10-12','22 kg','75 s',NULL),
('ABC','Treino A — Peito e tríceps',3,'Crucifixo na máquina','Peito',3,'12','35 kg','60 s','Alongar bem na fase excêntrica'),
('ABC','Treino A — Peito e tríceps',4,'Tríceps corda','Tríceps',3,'12-15','25 kg','60 s','Sem roubar no movimento'),
('ABC','Treino A — Peito e tríceps',5,'Tríceps testa','Tríceps',3,'10-12','25 kg','60 s',NULL),
('ABC','Treino B — Costas e bíceps',1,'Puxada frontal','Costas',4,'10','50 kg','90 s','Amplitude completa'),
('ABC','Treino B — Costas e bíceps',2,'Remada baixa','Costas',3,'10-12','45 kg','75 s',NULL),
('ABC','Treino B — Costas e bíceps',3,'Remada curvada','Costas',3,'10','40 kg','75 s','Coluna neutra'),
('ABC','Treino B — Costas e bíceps',4,'Rosca direta','Bíceps',3,'10-12','20 kg','60 s',NULL),
('ABC','Treino B — Costas e bíceps',5,'Rosca martelo','Bíceps',3,'12','12 kg','60 s',NULL),
('ABC','Treino C — Pernas e ombros',1,'Agachamento livre','Quadríceps',4,'8-10','70 kg','120 s','Profundidade até paralelo'),
('ABC','Treino C — Pernas e ombros',2,'Leg press 45°','Quadríceps',4,'12','160 kg','90 s',NULL),
('ABC','Treino C — Pernas e ombros',3,'Cadeira extensora','Quadríceps',3,'12-15','45 kg','60 s',NULL),
('ABC','Treino C — Pernas e ombros',4,'Desenvolvimento com halteres','Ombros',3,'10','18 kg','75 s',NULL),
('ABC','Treino C — Pernas e ombros',5,'Elevação lateral','Ombros',3,'12-15','8 kg','45 s','Cotovelos levemente flexionados'),
('FULLBODY','Full Body A',1,'Agachamento no Smith','Quadríceps',3,'12','30 kg','75 s',NULL),
('FULLBODY','Full Body A',2,'Supino na máquina','Peito',3,'12','30 kg','60 s',NULL),
('FULLBODY','Full Body A',3,'Puxada frontal','Costas',3,'12','35 kg','60 s',NULL),
('FULLBODY','Full Body A',4,'Elevação lateral','Ombros',2,'15','5 kg','45 s',NULL),
('FULLBODY','Full Body A',5,'Prancha abdominal','Abdômen',3,'30 s','Peso corporal','45 s',NULL),
('FULLBODY','Full Body B',1,'Leg press 45°','Quadríceps',3,'12','100 kg','75 s',NULL),
('FULLBODY','Full Body B',2,'Remada baixa','Costas',3,'12','35 kg','60 s',NULL),
('FULLBODY','Full Body B',3,'Desenvolvimento na máquina','Ombros',3,'12','20 kg','60 s',NULL),
('FULLBODY','Full Body B',4,'Rosca direta','Bíceps',2,'12','12 kg','45 s',NULL),
('FULLBODY','Full Body B',5,'Tríceps corda','Tríceps',2,'12','15 kg','45 s',NULL),
('FULLBODY','Full Body B',6,'Abdominal infra','Abdômen',3,'15','Peso corporal','45 s',NULL),
('FULLBODY','Full Body C',1,'Stiff com halteres','Posterior de coxa',3,'12','14 kg','75 s','Quadril para trás, coluna neutra'),
('FULLBODY','Full Body C',2,'Supino inclinado com halteres','Peito',3,'12','14 kg','60 s',NULL),
('FULLBODY','Full Body C',3,'Remada unilateral','Costas',3,'12','16 kg','60 s',NULL),
('FULLBODY','Full Body C',4,'Afundo','Pernas',3,'10 por perna','10 kg','60 s',NULL),
('FULLBODY','Full Body C',5,'Prancha lateral','Abdômen',3,'20 s','Peso corporal','45 s',NULL),
('EMAGRECIMENTO','Circuito 1 — Força e metabólico',1,'Agachamento goblet','Pernas',4,'15','12 kg','30 s',NULL),
('EMAGRECIMENTO','Circuito 1 — Força e metabólico',2,'Flexão de braço','Peito',4,'12','Peso corporal','30 s','Joelhos no chão se necessário'),
('EMAGRECIMENTO','Circuito 1 — Força e metabólico',3,'Remada com elástico','Costas',4,'15','Elástico médio','30 s',NULL),
('EMAGRECIMENTO','Circuito 1 — Força e metabólico',4,'Burpee','Corpo inteiro',4,'10','Peso corporal','45 s',NULL),
('EMAGRECIMENTO','Circuito 1 — Força e metabólico',5,'Corda naval','Corpo inteiro',4,'30 s','—','45 s',NULL),
('EMAGRECIMENTO','Cardio e core',1,'Esteira intervalada','Cardio',1,'20 min','Tiros 1:1','—','30 s forte / 30 s leve'),
('EMAGRECIMENTO','Cardio e core',2,'Bicicleta ergométrica','Cardio',1,'15 min','Moderada','—',NULL),
('EMAGRECIMENTO','Cardio e core',3,'Prancha abdominal','Abdômen',3,'40 s','Peso corporal','30 s',NULL),
('EMAGRECIMENTO','Cardio e core',4,'Abdominal bicicleta','Abdômen',3,'20','Peso corporal','30 s',NULL),
('EMAGRECIMENTO','Cardio e core',5,'Elevação de pernas','Abdômen',3,'15','Peso corporal','30 s',NULL),
('EMAGRECIMENTO','Circuito 2 — Corpo inteiro',1,'Leg press 45°','Quadríceps',4,'15','80 kg','30 s',NULL),
('EMAGRECIMENTO','Circuito 2 — Corpo inteiro',2,'Supino na máquina','Peito',4,'15','25 kg','30 s',NULL),
('EMAGRECIMENTO','Circuito 2 — Corpo inteiro',3,'Puxada frontal','Costas',4,'15','30 kg','30 s',NULL),
('EMAGRECIMENTO','Circuito 2 — Corpo inteiro',4,'Stiff com halteres','Posterior de coxa',3,'15','12 kg','45 s',NULL),
('EMAGRECIMENTO','Circuito 2 — Corpo inteiro',5,'Polichinelo','Cardio',4,'40 s','—','20 s',NULL),
('EMAGRECIMENTO','Circuito 2 — Corpo inteiro',6,'Mountain climber','Abdômen',4,'30 s','Peso corporal','30 s',NULL),
('GLUTEOS','Treino A — Glúteos e posterior',1,'Agachamento sumô','Glúteos',4,'10-12','30 kg','90 s',NULL),
('GLUTEOS','Treino A — Glúteos e posterior',2,'Hip thrust','Glúteos',4,'10-12','60 kg','90 s','Pausa de 1 s no topo'),
('GLUTEOS','Treino A — Glúteos e posterior',3,'Stiff','Posterior de coxa',3,'12','30 kg','75 s',NULL),
('GLUTEOS','Treino A — Glúteos e posterior',4,'Mesa flexora','Posterior de coxa',3,'12','30 kg','60 s',NULL),
('GLUTEOS','Treino A — Glúteos e posterior',5,'Abdução de quadril na máquina','Glúteos',3,'15','40 kg','45 s',NULL),
('GLUTEOS','Treino B — Superiores e core',1,'Puxada frontal','Costas',3,'12','35 kg','60 s',NULL),
('GLUTEOS','Treino B — Superiores e core',2,'Supino na máquina','Peito',3,'12','25 kg','60 s',NULL),
('GLUTEOS','Treino B — Superiores e core',3,'Desenvolvimento com halteres','Ombros',3,'12','8 kg','60 s',NULL),
('GLUTEOS','Treino B — Superiores e core',4,'Rosca direta','Bíceps',2,'12','8 kg','45 s',NULL),
('GLUTEOS','Treino B — Superiores e core',5,'Prancha abdominal','Abdômen',3,'40 s','Peso corporal','30 s',NULL),
('GLUTEOS','Treino C — Glúteos e quadríceps',1,'Leg press 45° (pés altos)','Glúteos',4,'12','120 kg','90 s',NULL),
('GLUTEOS','Treino C — Glúteos e quadríceps',2,'Afundo búlgaro','Glúteos',3,'10 por perna','12 kg','75 s',NULL),
('GLUTEOS','Treino C — Glúteos e quadríceps',3,'Cadeira extensora','Quadríceps',3,'12-15','35 kg','60 s',NULL),
('GLUTEOS','Treino C — Glúteos e quadríceps',4,'Elevação pélvica unilateral','Glúteos',3,'12 por perna','Peso corporal','60 s',NULL),
('GLUTEOS','Treino C — Glúteos e quadríceps',5,'Cadeira abdutora','Glúteos',3,'15','45 kg','45 s',NULL),
('UPPER_LOWER','Upper A — Força',1,'Supino reto','Peito',4,'6-8','80 kg','120 s',NULL),
('UPPER_LOWER','Upper A — Força',2,'Remada curvada','Costas',4,'6-8','70 kg','120 s',NULL),
('UPPER_LOWER','Upper A — Força',3,'Desenvolvimento militar','Ombros',3,'8','40 kg','90 s',NULL),
('UPPER_LOWER','Upper A — Força',4,'Barra fixa','Costas',3,'8','Peso corporal','90 s',NULL),
('UPPER_LOWER','Upper A — Força',5,'Rosca direta com barra','Bíceps',3,'10','30 kg','60 s',NULL),
('UPPER_LOWER','Lower A — Força',1,'Agachamento livre','Quadríceps',5,'5','100 kg','150 s','Usar cinto nas séries pesadas'),
('UPPER_LOWER','Lower A — Força',2,'Stiff','Posterior de coxa',4,'8','70 kg','120 s',NULL),
('UPPER_LOWER','Lower A — Força',3,'Leg press 45°','Quadríceps',3,'10','200 kg','90 s',NULL),
('UPPER_LOWER','Lower A — Força',4,'Panturrilha em pé','Panturrilha',4,'12','60 kg','45 s',NULL),
('UPPER_LOWER','Lower A — Força',5,'Abdominal na polia','Abdômen',3,'12','30 kg','45 s',NULL),
('UPPER_LOWER','Upper B — Volume',1,'Supino inclinado com halteres','Peito',4,'10','24 kg','75 s',NULL),
('UPPER_LOWER','Upper B — Volume',2,'Puxada frontal','Costas',4,'10','60 kg','75 s',NULL),
('UPPER_LOWER','Upper B — Volume',3,'Elevação lateral','Ombros',4,'12','10 kg','45 s',NULL),
('UPPER_LOWER','Upper B — Volume',4,'Tríceps testa','Tríceps',3,'12','30 kg','60 s',NULL),
('UPPER_LOWER','Upper B — Volume',5,'Rosca alternada','Bíceps',3,'12','14 kg','60 s',NULL),
('UPPER_LOWER','Lower B — Volume',1,'Agachamento frontal','Quadríceps',4,'8','60 kg','120 s',NULL),
('UPPER_LOWER','Lower B — Volume',2,'Cadeira extensora','Quadríceps',4,'12','55 kg','60 s',NULL),
('UPPER_LOWER','Lower B — Volume',3,'Mesa flexora','Posterior de coxa',4,'12','40 kg','60 s',NULL),
('UPPER_LOWER','Lower B — Volume',4,'Hip thrust','Glúteos',4,'10','80 kg','90 s',NULL),
('UPPER_LOWER','Lower B — Volume',5,'Panturrilha sentada','Panturrilha',4,'15','40 kg','45 s',NULL);

-- fichas (data_inicio = hoje - ini_dias; data_revisao = hoje + rev_dias)
INSERT INTO fichas_treino(aluno_id,professor_id,nome,objetivo,frequencia_semanal,data_inicio,data_revisao,observacoes,status)
SELECT a.id, pr.id, tf.nome, tf.objetivo, tf.freq,
       DATE_SUB(CURDATE(), INTERVAL tf.ini_dias DAY),
       DATE_ADD(CURDATE(), INTERVAL tf.rev_dias DAY),
       tf.obs, tf.status
FROM tmp_fichas tf
JOIN usuarios ua ON ua.username = tf.aluno_user
JOIN alunos   a  ON a.usuario_id = ua.id
JOIN usuarios up ON up.username = tf.prof_user
JOIN professores pr ON pr.usuario_id = up.id
WHERE NOT EXISTS (SELECT 1 FROM fichas_treino f WHERE f.aluno_id = a.id AND f.nome = tf.nome);

-- treinos de cada ficha
INSERT INTO treinos(ficha_id,nome,dia_semana,descricao)
SELECT f.id, tt.nome, tt.dia_semana, tt.descricao
FROM tmp_fichas tf
JOIN usuarios u ON u.username = tf.aluno_user
JOIN alunos   a ON a.usuario_id = u.id
JOIN fichas_treino f ON f.aluno_id = a.id AND f.nome = tf.nome
JOIN tmp_treino_tpl tt ON tt.tpl = tf.tpl
WHERE NOT EXISTS (SELECT 1 FROM treinos x WHERE x.ficha_id = f.id AND x.nome = tt.nome)
ORDER BY f.id, tt.ordem;

-- exercícios de cada treino
INSERT INTO exercicios(treino_id,nome,grupo_muscular,series,repeticoes,carga,descanso,observacoes)
SELECT t.id, et.nome, et.grupo, et.series, et.repeticoes, et.carga, et.descanso, et.obs
FROM tmp_fichas tf
JOIN usuarios u ON u.username = tf.aluno_user
JOIN alunos   a ON a.usuario_id = u.id
JOIN fichas_treino f ON f.aluno_id = a.id AND f.nome = tf.nome
JOIN treinos t ON t.ficha_id = f.id
JOIN tmp_ex_tpl et ON et.tpl = tf.tpl AND et.treino = t.nome
WHERE NOT EXISTS (SELECT 1 FROM exercicios x WHERE x.treino_id = t.id AND x.nome = et.nome)
ORDER BY t.id, et.ordem;


-- =====================================================================
-- 5) AVALIAÇÕES FÍSICAS (evolução ao longo do tempo)
-- =====================================================================
CREATE TEMPORARY TABLE tmp_aval (
    aluno_user VARCHAR(60), prof_user VARCHAR(60), dias_atras INT,
    peso DECIMAL(6,2), altura DECIMAL(4,2), gordura DECIMAL(5,2), obs TEXT
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tmp_aval VALUES
('bruno.oliveira','thiago.barbosa',180,84.2,1.8,19.8,'Avaliação inicial.'),
('bruno.oliveira','thiago.barbosa',90,85.6,1.8,18.6,'Reavaliação 1 — ganho de massa magra.'),
('bruno.oliveira','thiago.barbosa',7,86.9,1.8,17.9,'Reavaliação 2 — boa evolução de força.'),
('elisa.barros','larissa.nogueira',150,62.4,1.68,26.1,'Avaliação inicial.'),
('elisa.barros','larissa.nogueira',75,61.2,1.68,24.3,'Reavaliação 1.'),
('elisa.barros','larissa.nogueira',10,60.5,1.68,23.2,'Reavaliação 2 — resistência melhorou.'),
('henrique.castro','thiago.barbosa',200,96.8,1.83,22.4,'Avaliação inicial.'),
('henrique.castro','thiago.barbosa',100,98.1,1.83,21.5,'Reavaliação 1.'),
('henrique.castro','thiago.barbosa',12,99.0,1.83,20.8,'Reavaliação 2 — força em alta.'),
('leandro.gomes','larissa.nogueira',170,91.5,1.76,27.3,'Avaliação inicial.'),
('leandro.gomes','larissa.nogueira',85,88.2,1.76,25.1,'Reavaliação 1 — perda de gordura consistente.'),
('leandro.gomes','larissa.nogueira',14,85.7,1.76,23.4,'Reavaliação 2.'),
('rafaela.matos','juliana.costa',120,82.0,1.65,34.0,'Avaliação inicial.'),
('rafaela.matos','juliana.costa',60,78.4,1.65,31.2,'Reavaliação 1.'),
('rafaela.matos','juliana.costa',8,75.1,1.65,28.5,'Reavaliação 2 — meta parcial atingida.'),
('augusto.lima','thiago.barbosa',5,79.3,1.77,21.0,'Avaliação inicial.'),
('ana.souza','rafael.mendes',100,64.8,1.66,27.5,'Avaliação inicial.'),
('ana.souza','rafael.mendes',20,65.9,1.66,25.9,'Reavaliação — ganho de massa magra.'),
('fernando.alves','larissa.nogueira',110,88.6,1.72,28.9,'Avaliação inicial.'),
('fernando.alves','larissa.nogueira',25,86.1,1.72,26.8,'Reavaliação.'),
('karina.dias','juliana.costa',130,70.2,1.62,31.5,'Avaliação inicial.'),
('olivia.cardoso','larissa.nogueira',140,68.3,1.6,33.1,'Avaliação inicial.'),
('olivia.cardoso','larissa.nogueira',30,67.0,1.6,31.8,'Reavaliação.'),
('isabela.ramos','juliana.costa',45,58.9,1.64,25.2,'Avaliação inicial.'),
('mariana.lopes','rafael.mendes',60,61.4,1.7,24.7,'Avaliação inicial.'),
('samuel.araujo','thiago.barbosa',90,82.3,1.79,23.8,'Avaliação inicial.'),
('vinicius.teixeira','rafael.mendes',35,72.1,1.81,15.6,'Avaliação inicial.'),
('diego.martins','rafael.mendes',50,74.5,1.75,17.9,'Avaliação inicial.');

INSERT INTO avaliacoes_fisicas(aluno_id,professor_id,data_avaliacao,peso,altura,percentual_gordura,observacoes)
SELECT a.id, pr.id, DATE_SUB(CURDATE(), INTERVAL tv.dias_atras DAY), tv.peso, tv.altura, tv.gordura, tv.obs
FROM tmp_aval tv
JOIN usuarios ua ON ua.username = tv.aluno_user
JOIN alunos   a  ON a.usuario_id = ua.id
JOIN usuarios up ON up.username = tv.prof_user
JOIN professores pr ON pr.usuario_id = up.id
WHERE NOT EXISTS (SELECT 1 FROM avaliacoes_fisicas x WHERE x.aluno_id = a.id AND x.observacoes = tv.obs);

DROP TEMPORARY TABLE IF EXISTS tmp_equipe;
DROP TEMPORARY TABLE IF EXISTS tmp_alunos;
DROP TEMPORARY TABLE IF EXISTS tmp_fichas;
DROP TEMPORARY TABLE IF EXISTS tmp_treino_tpl;
DROP TEMPORARY TABLE IF EXISTS tmp_ex_tpl;
DROP TEMPORARY TABLE IF EXISTS tmp_aval;

-- Conferência rápida
SELECT 'usuarios' AS tabela, COUNT(*) AS qtd FROM usuarios
UNION ALL SELECT 'funcionarios', COUNT(*) FROM funcionarios
UNION ALL SELECT 'professores', COUNT(*) FROM professores
UNION ALL SELECT 'alunos', COUNT(*) FROM alunos
UNION ALL SELECT 'pagamentos', COUNT(*) FROM pagamentos
UNION ALL SELECT 'fichas_treino', COUNT(*) FROM fichas_treino
UNION ALL SELECT 'treinos', COUNT(*) FROM treinos
UNION ALL SELECT 'exercicios', COUNT(*) FROM exercicios
UNION ALL SELECT 'avaliacoes_fisicas', COUNT(*) FROM avaliacoes_fisicas;
