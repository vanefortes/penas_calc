// lib/screens/editor_foto_screen.dart
// Permite ao usuário reposicionar e redimensionar a foto de perfil
// arrastando e fazendo pinch dentro de um recorte circular.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class EditorFotoScreen extends StatefulWidget {
  const EditorFotoScreen({super.key});

  @override
  State<EditorFotoScreen> createState() => _EditorFotoScreenState();
}

class _EditorFotoScreenState extends State<EditorFotoScreen> {
  late double _offsetX;
  late double _offsetY;
  late double _scale;

  // Para calcular delta do drag
  double _startOffsetX = 0;
  double _startOffsetY = 0;
  double _startScale   = 1;

  static const double _previewSize = 280.0;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _offsetX = state.fotoOffsetX;
    _offsetY = state.fotoOffsetY;
    _scale   = state.fotoScale.clamp(0.5, 4.0);
  }

  Future<void> _salvar() async {
    await context.read<AppState>().setFotoTransform(
      offsetX: _offsetX,
      offsetY: _offsetY,
      scale: _scale,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _resetar() => setState(() {
    _offsetX = 0;
    _offsetY = 0;
    _scale   = 1;
  });

  @override
  Widget build(BuildContext context) {
    final state   = context.read<AppState>();
    final foto    = state.usuarioFoto;
    final primary = Theme.of(context).colorScheme.primary;

    if (foto.isEmpty) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    final bytes = base64Decode(foto.split(',').last);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          const Icon(Icons.crop_rounded, size: 18),
          const SizedBox(width: 10),
          const Text('Ajustar foto'),
        ]),
        actions: [
          TextButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Salvar'),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Preview com drag e pinch ─────────────────────────
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Arraste para reposicionar · Pinça para zoom',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.labelSmall?.color,
                    )),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onScaleStart: (d) {
                      _startOffsetX = _offsetX;
                      _startOffsetY = _offsetY;
                      _startScale   = _scale;
                    },
                    onScaleUpdate: (d) {
                      setState(() {
                        _scale = (_startScale * d.scale).clamp(0.5, 4.0);
                        _offsetX = _startOffsetX + d.focalPointDelta.dx;
                        _offsetY = _startOffsetY + d.focalPointDelta.dy;
                      });
                    },
                    child: SizedBox(
                      width: _previewSize,
                      height: _previewSize,
                      child: ClipOval(
                        child: OverflowBox(
                          maxWidth: double.infinity,
                          maxHeight: double.infinity,
                          child: Transform.translate(
                            offset: Offset(_offsetX, _offsetY),
                            child: Transform.scale(
                              scale: _scale,
                              child: Image.memory(
                                Uint8List.fromList(bytes),
                                width: _previewSize,
                                height: _previewSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Borda decorativa ao redor do círculo
                  Text('Prévia circular do avatar',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.labelSmall?.color,
                    )),
                ],
              ),
            ),
          ),

          // ── Controles de zoom ────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(top: BorderSide(
                color: Theme.of(context).dividerTheme.color ??
                    Colors.grey.withOpacity(0.2),
                width: 0.5,
              )),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.zoom_out_rounded, size: 18,
                    color: Theme.of(context).textTheme.labelSmall?.color),
                  Expanded(
                    child: Slider(
                      value: _scale.clamp(0.5, 4.0),
                      min: 0.5, max: 4.0,
                      divisions: 70,
                      activeColor: primary,
                      onChanged: (v) => setState(() => _scale = v),
                    ),
                  ),
                  Icon(Icons.zoom_in_rounded, size: 18,
                    color: Theme.of(context).textTheme.labelSmall?.color),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Zoom: ${(_scale * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(fontSize: 12,
                      color: Theme.of(context).textTheme.labelSmall?.color)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetar,
                    icon: const Icon(Icons.center_focus_strong_rounded, size: 15),
                    label: const Text('Centralizar'),
                    style: TextButton.styleFrom(
                      foregroundColor: primary,
                      textStyle: GoogleFonts.inter(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // ── Botões principais ────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(
                  color: Theme.of(context).dividerTheme.color ??
                      Colors.grey.withOpacity(0.2),
                  width: 0.5,
                )),
              ),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
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
                    onPressed: _salvar,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Aplicar ajuste'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
