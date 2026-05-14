// lib/screens/editar_cadastro_screen.dart
// Tela dedicada para edição dos dados cadastrais.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/avatar_perfil.dart';

class EditarCadastroScreen extends StatefulWidget {
  const EditarCadastroScreen({super.key});

  @override
  State<EditarCadastroScreen> createState() => _EditarCadastroScreenState();
}

class _EditarCadastroScreenState extends State<EditarCadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _oab;
  late final TextEditingController _email;
  late bool _biometria;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final s  = context.read<AppState>();
    _nome    = TextEditingController(text: s.usuarioNome);
    _oab     = TextEditingController(text: s.usuarioOab);
    _email   = TextEditingController(text: s.usuarioEmail);
    _biometria = s.biometriaAtiva;
  }

  @override
  void dispose() {
    _nome.dispose(); _oab.dispose(); _email.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_temAlteracoes()) {
      final sair = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text('As alterações não salvas serão perdidas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Continuar editando'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      return sair ?? false;
    }
    return true;
  }

  bool _temAlteracoes() {
    final s = context.read<AppState>();
    return _nome.text.trim() != s.usuarioNome ||
        _oab.text.trim() != s.usuarioOab ||
        _email.text.trim() != s.usuarioEmail ||
        _biometria != s.biometriaAtiva;
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    if (_salvando) return;
    setState(() => _salvando = true);

    await context.read<AppState>().completarPrimeiroAcesso(
      nome: _nome.text.trim(),
      oab: _oab.text.trim(),
      email: _email.text.trim(),
      biometria: _biometria,
    );

    if (!mounted) return;
    setState(() => _salvando = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text('Dados salvos com sucesso!', style: GoogleFonts.inter(fontSize: 13)),
      ]),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));

    Navigator.of(context).pop(true); // retorna true = salvou
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final sair = await _onWillPop();
        if (sair && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancelar',
            onPressed: () async {
              final sair = await _onWillPop();
              if (sair && context.mounted) Navigator.of(context).pop();
            },
          ),
          title: Row(children: [
            const Icon(Icons.edit_rounded, size: 18),
            const SizedBox(width: 10),
            const Text('Editar cadastro'),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded, size: 16),
                label: Text(_salvando ? 'Salvando...' : 'Salvar'),
                style: TextButton.styleFrom(
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                width: 0.5,
              )),
            ),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final sair = await _onWillPop();
                    if (sair && context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar dados'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ]),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de aviso
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primary.withOpacity(0.2), width: 0.8),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Altere os campos desejados e toque em Salvar para confirmar.',
                        style: GoogleFonts.inter(fontSize: 12, color: primary, height: 1.4),
                      ),
                    ),
                  ]),
                ),

                // Avatar editável centralizado
                Center(
                  child: Column(children: [
                    const AvatarPerfil(size: 90, editavel: true),
                    const SizedBox(height: 8),
                    Text('Toque para alterar a foto',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.labelSmall?.color,
                      )),
                    const SizedBox(height: 20),
                  ]),
                ),

                _sectionTitle(context, 'Identificação profissional'),
                const SizedBox(height: 10),

                // Nome
                _buildField(
                  context,
                  label: 'Nome do(a) advogado(a)',
                  hint: 'Dr(a). seu nome',
                  controller: _nome,
                  icon: Icons.person_rounded,
                  isDark: isDark,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 12),

                // OAB
                _buildField(
                  context,
                  label: 'OAB / UF',
                  hint: '123.456 / SP',
                  controller: _oab,
                  icon: Icons.shield_rounded,
                  isDark: isDark,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a OAB' : null,
                ),
                const SizedBox(height: 12),

                // E-mail
                _buildField(
                  context,
                  label: 'E-mail (opcional)',
                  hint: 'contato@escritorio.com',
                  controller: _email,
                  icon: Icons.mail_outline_rounded,
                  keyboard: TextInputType.emailAddress,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                _sectionTitle(context, 'Segurança'),
                const SizedBox(height: 10),

                // Biometria
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(children: [
                    Icon(Icons.fingerprint_rounded, size: 22,
                      color: Theme.of(context).textTheme.titleMedium?.color),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Proteção biométrica',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleMedium?.color)),
                      const SizedBox(height: 2),
                      Text('Face ID / Touch ID ao abrir',
                        style: GoogleFonts.inter(fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                    ])),
                    Switch.adaptive(
                      value: _biometria,
                      onChanged: (v) => setState(() => _biometria = v),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    bool autofocus = false,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final fg      = Theme.of(context).textTheme.titleMedium?.color
        ?? (isDark ? Colors.white : Colors.black87);
    final dim     = Theme.of(context).textTheme.labelSmall?.color
        ?? (isDark ? Colors.white54 : Colors.black45);
    final cardBg  = Theme.of(context).cardTheme.color
        ?? (isDark ? const Color(0xFF1C2025) : Colors.white);

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBg,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary.withOpacity(0.25), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary.withOpacity(0.25), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        autofocus: autofocus,
        cursorColor: primary,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 15, color: fg),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: dim),
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 14, color: dim.withOpacity(0.5)),
          prefixIcon: Icon(icon, size: 18, color: primary.withOpacity(0.6)),
          floatingLabelStyle: GoogleFonts.inter(fontSize: 12, color: primary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(
    title.toUpperCase(),
    style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.7,
      color: Theme.of(context).textTheme.labelSmall?.color,
    ),
  );
}
