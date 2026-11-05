package br.com.vidaativa.service;

import java.util.regex.Pattern;

/**
 * Validações simples dos campos de formulário. Todas lançam {@link IllegalArgumentException} com mensagem pronta para
 * ser mostrada ao usuário, e a maioria devolve o valor já limpo (sem espaços nas pontas, e-mail em minúsculas), então o
 * uso normal é {@code email = Validacao.email(email);}.
 *
 * <p>Quem usa: os DAOs de cadastro ({@code AlunoDAO}, {@code FuncionarioDAO}, {@code ProfessorDAO}, {@code UsuarioDAO}, {@code FichaTreinoDAO}),
 * que validam ANTES de abrir transação no banco, e a troca de senha do aluno no site (a mensagem vira o erro 400 da API).
 *
 * <p>Limites conhecidos: são checagens de formato, não de existência. O documento só exige 5+ letras/números (NÃO confere
 * os dígitos verificadores do CPF) e o telefone só exige 10+ dígitos (DDD + número). O documento e o telefone são devolvidos
 * como foram digitados (apenas sem espaços nas pontas), sem remover pontos e traços.
 */
public final class Validacao {
    // E-mail: algo@algo.algo, sem espaços. Propositalmente simples: o formato real de e-mail é complexo demais para uma regex.
    private static final Pattern EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    // Usuário: só minúsculas (a entrada é convertida antes de comparar), números, ponto, hífen e sublinhado; 3 a 30 caracteres.
    private static final Pattern USERNAME = Pattern.compile("^[a-z0-9._-]{3,30}$");

    private Validacao() { }

    /**
     * Garante que o campo foi preenchido (não nulo e não só espaços).
     *
     * @param campo nome do campo, usado na mensagem de erro ("Preencha o campo ...")
     * @return o valor sem espaços nas pontas
     */
    public static String obrigatorio(String valor, String campo) {
        if (valor == null || valor.trim().isEmpty()) throw new IllegalArgumentException("Preencha o campo \"" + campo + "\".");
        return valor.trim();
    }

    /** Obrigatório, no formato de e-mail; devolve em minúsculas e sem espaços nas pontas. */
    public static String email(String valor) {
        String v = obrigatorio(valor, "E-mail").toLowerCase();
        if (!EMAIL.matcher(v).matches()) throw new IllegalArgumentException("E-mail inválido.");
        return v;
    }

    /** Usuário em minúsculas, 3 a 30 caracteres: letras, números, ponto, hífen e sublinhado. */
    public static String username(String valor) {
        String v = obrigatorio(valor, "Usuário").toLowerCase();
        if (!USERNAME.matcher(v).matches())
            throw new IllegalArgumentException("Usuário deve ter de 3 a 30 caracteres: letras minúsculas, números, ponto, hífen ou sublinhado (sem espaços).");
        return v;
    }

    /** Mínimo de 6 caracteres. Devolve a senha SEM alteração (espaços contam e não são removidos). */
    public static String senha(String valor) {
        if (valor == null || valor.length() < 6) throw new IllegalArgumentException("A senha deve ter no mínimo 6 caracteres.");
        return valor;
    }

    /** Obrigatório e com pelo menos 5 letras/números (ignora pontos, traços e espaços na contagem). Devolve como digitado. */
    public static String documento(String valor) {
        String v = obrigatorio(valor, "Documento (CPF ou RG)");
        // Conta só letras e números porque o documento pode ser CPF (com pontos e traço) ou RG (que pode ter letra).
        String digitos = v.replaceAll("[^0-9A-Za-z]", "");
        if (digitos.length() < 5) throw new IllegalArgumentException("Documento inválido.");
        return v;
    }

    /** Obrigatório e com pelo menos 10 dígitos (DDD + número). Devolve como digitado, com a máscara que vier. */
    public static String telefone(String valor) {
        String v = obrigatorio(valor, "Telefone");
        if (v.replaceAll("\\D", "").length() < 10) throw new IllegalArgumentException("Telefone inválido. Informe DDD + número.");
        return v;
    }

    /** Para campos opcionais: converte texto vazio ou só espaços em null (vira NULL no banco); senão devolve sem espaços nas pontas. */
    public static String opcional(String valor) {
        return valor == null || valor.trim().isEmpty() ? null : valor.trim();
    }
}
