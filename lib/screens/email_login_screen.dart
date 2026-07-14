// lib/screens/email_login_screen.dart
// Tela de login/cadastro por e-mail e senha, via Firebase Authentication.
//
// Ao concluir com sucesso, retorna o e-mail autenticado via
// `Navigator.pop(email)` para quem abriu esta tela preencher o próprio
// campo de e-mail — o mesmo padrão já usado pelo fluxo de login com
// Google/Apple nas telas `primeiro_acesso_screen.dart` e
// `editar_cadastro_screen.dart`.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/email_auth_service.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _modoCadastro = false;
  bool _carregando = false;
  bool _senhaVisivel = false;

  /// Quando `true`, exibe a tela de "confirme seu e-mail" em vez do
  /// formulário — usada tanto logo após o cadastro quanto quando um
  /// usuário existente tenta entrar sem ter confirmado o e-mail ainda.
  bool _aguardandoVerificacao = false;
  String? _emailPendente;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  String? _validarEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
    final ok =
        RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());
    return ok ? null : 'E-mail inválido';
  }

  String? _validarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Informe a senha';
    if (v.length < 6) return 'Mínimo de 6 caracteres';
    return null;
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _carregando = true);

    final email = _email.text.trim();
    final senha = _senha.text;

    try {
      if (_modoCadastro) {
        await EmailAuthService.signUp(email: email, password: senha);
        // Conta recém-criada: envia o e-mail de verificação e trava o
        // acesso até que o usuário confirme.
        await EmailAuthService.sendEmailVerification();
        if (!mounted) return;
        setState(() {
          _aguardandoVerificacao = true;
          _emailPendente = email;
        });
        return;
      }

      await EmailAuthService.signIn(email: email, password: senha);
      final verificado = await EmailAuthService.isEmailVerified();
      if (!mounted) return;

      if (verificado) {
        Navigator.of(context).pop(email);
      } else {
        // Conta existente, mas ainda não confirmada.
        setState(() {
          _aguardandoVerificacao = true;
          _emailPendente = email;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _mostrarErro(_mensagemErro(e));
    } catch (_) {
      if (!mounted) return;
      _mostrarErro('Não foi possível concluir. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Reenvia o e-mail de verificação (usuário pode ter perdido o
  /// primeiro, ou ele pode ter caído no spam).
  Future<void> _reenviarVerificacao() async {
    setState(() => _carregando = true);
    try {
      await EmailAuthService.sendEmailVerification();
      if (!mounted) return;
      _mostrarInfo('E-mail de verificação reenviado.');
    } catch (_) {
      if (!mounted) return;
      _mostrarErro('Não foi possível reenviar agora. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Verifica se o e-mail já foi confirmado e, se sim, conclui o fluxo.
  Future<void> _jaConfirmei() async {
    setState(() => _carregando = true);
    final verificado = await EmailAuthService.isEmailVerified();
    if (!mounted) return;
    setState(() => _carregando = false);

    if (verificado) {
      Navigator.of(context).pop(_emailPendente);
    } else {
      _mostrarErro(
        'Ainda não identificamos a confirmação. Verifique sua caixa de '
        'entrada (e o spam) e tente de novo.',
      );
    }
  }

  /// Cancela a espera de verificação e volta para o formulário. Encerra
  /// a sessão criada, já que ela ainda não está verificada.
  Future<void> _cancelarVerificacao() async {
    await EmailAuthService.signOut();
    if (!mounted) return;
    setState(() {
      _aguardandoVerificacao = false;
      _emailPendente = null;
    });
  }

  Future<void> _recuperarSenha() async {
    final email = _email.text.trim();
    if (_validarEmail(email) != null) {
      _mostrarErro('Digite um e-mail válido para recuperar a senha.');
      return;
    }
    try {
      await EmailAuthService.sendPasswordReset(email);
      if (!mounted) return;
      _mostrarInfo('Enviamos um e-mail para redefinir sua senha.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _mostrarErro(_mensagemErro(e));
    }
  }

  String _mensagemErro(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Tente entrar.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-not-found':
        return 'Nenhuma conta encontrada com esse e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha incorreta.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento e tente de novo.';
      default:
        return 'Erro: ${e.message ?? e.code}';
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _mostrarInfo(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem, style: GoogleFonts.inter(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_aguardandoVerificacao
            ? 'Confirme seu e-mail'
            : (_modoCadastro ? 'Criar conta' : 'Entrar com e-mail')),
      ),
      body: SafeArea(
        child: _aguardandoVerificacao
            ? _buildAguardandoVerificacao(context)
            : _buildFormulario(context),
      ),
    );
  }

  Widget _buildAguardandoVerificacao(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.mark_email_unread_rounded,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'Enviamos um link de confirmação para:',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            _emailPendente ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Text(
            'Abra o e-mail e toque no link de confirmação. Se não '
            'encontrar, confira também a pasta de spam.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _carregando ? null : _jaConfirmei,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _carregando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Já confirmei, continuar',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _carregando ? null : _reenviarVerificacao,
            child: Text('Reenviar e-mail de confirmação',
                style: GoogleFonts.inter(fontSize: 13)),
          ),
          TextButton(
            onPressed: _carregando ? null : _cancelarVerificacao,
            child: Text('Cancelar e voltar',
                style: GoogleFonts.inter(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario(BuildContext context) {
    return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _modoCadastro
                      ? 'Crie uma conta com e-mail e senha.'
                      : 'Entre com seu e-mail e senha.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _validarEmail,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _senha,
                  obscureText: !_senhaVisivel,
                  autofillHints: [
                    _modoCadastro
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  validator: _validarSenha,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_senhaVisivel
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () =>
                          setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (!_modoCadastro)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _carregando ? null : _recuperarSenha,
                      child: Text('Esqueci minha senha',
                          style: GoogleFonts.inter(fontSize: 12)),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _carregando ? null : _enviar,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _modoCadastro ? 'Criar conta' : 'Entrar',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _carregando
                      ? null
                      : () => setState(() => _modoCadastro = !_modoCadastro),
                  child: Text(
                    _modoCadastro
                        ? 'Já tem uma conta? Entrar'
                        : 'Não tem conta? Criar agora',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
