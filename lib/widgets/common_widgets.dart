import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  const ResultCard({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hColor = highlightColor ?? AppTheme.accentColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.accentBg(context)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? hColor.withOpacity(0.4)
              : (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1)),
          width: highlight ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: highlight
                  ? hColor
                  : Theme.of(context).textTheme.labelSmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: highlight
                  ? hColor
                  : Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class FormulaBox extends StatelessWidget {
  final String text;
  const FormulaBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ??
              Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.sourceCodePro(
          fontSize: 12,
          height: 1.6,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

class AvisoLegal extends StatelessWidget {
  const AvisoLegal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.warningBg(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppTheme.warningColor(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Resultado Informativo: Confirmar com legislação aplicável e documentação do processo.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.warningColor(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ModoChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? const Color(0xFFD3D1C7)
                  : const Color(0xFF2C2C2A))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.2)),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w500 : FontWeight.w400,
            color: selected
                ? (isDark
                    ? const Color(0xFF1A1A18)
                    : Colors.white)
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

class CopyButton extends StatefulWidget {
  final String textToCopy;
  final String label;
  const CopyButton(
      {super.key, required this.textToCopy, this.label = 'Copiar'});

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _copy,
      icon: Icon(
        _copied ? Icons.check_rounded : Icons.copy_rounded,
        size: 15,
        color: _copied ? AppTheme.accentColor(context) : null,
      ),
      label: Text(
        _copied ? 'Copiado!' : widget.label,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: _copied ? AppTheme.accentColor(context) : null,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: BorderSide(
          color: _copied
              ? AppTheme.accentColor(context)
              : Theme.of(context).dividerTheme.color ?? Colors.grey,
          width: 0.5,
        ),
      ),
    );
  }
}

class PdfButton extends StatefulWidget {
  final Future<void> Function() onTap;
  const PdfButton({super.key, required this.onTap});

  @override
  State<PdfButton> createState() => _PdfButtonState();
}

class _PdfButtonState extends State<PdfButton> {
  bool _loading = false;

  Future<void> _gerar() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _gerar,
      icon: _loading
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.picture_as_pdf_rounded, size: 15),
      label: Text(
        _loading ? 'Gerando...' : 'PDF',
        style: GoogleFonts.inter(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        foregroundColor: Colors.red.shade600,
        side: BorderSide(color: Colors.red.shade300, width: 0.5),
      ),
    );
  }
}

class ProgressaoBadge extends StatelessWidget {
  const ProgressaoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.infoBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gavel_rounded,
              size: 12, color: AppTheme.infoColor(context)),
          const SizedBox(width: 4),
          Text(
            'Progressão',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.infoColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState(
      {super.key,
      required this.message,
      this.icon = Icons.history_rounded});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 40,
                color:
                    Theme.of(context).textTheme.labelSmall?.color),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
