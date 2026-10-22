final _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Checagem simples de formato (não garante que o e-mail exista) — só
/// evita uma ida desnecessária ao Firebase quando o texto digitado
/// claramente não é um e-mail.
bool emailValido(String email) => _regexEmail.hasMatch(email.trim());
