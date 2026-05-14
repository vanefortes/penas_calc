// lib/widgets/avatar_perfil.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class AvatarPerfil extends StatelessWidget {
  final double size;
  final bool editavel;

  const AvatarPerfil({super.key, this.size = 56, this.editavel = false});

  Future<void> _selecionarFoto(BuildContext context) async {
    final picker = ImagePicker();

    if (kIsWeb) {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, maxHeight: 512, imageQuality: 85,
      );
      if (picked == null || !context.mounted) return;
      final bytes = await picked.readAsBytes();
      final dataUrl = _toDataUrl(bytes, picked.name);
      await context.read<AppState>().setFotoPerfil(dataUrl);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final primary  = Theme.of(ctx).colorScheme.primary;
        final temFoto  = ctx.read<AppState>().usuarioFoto.isNotEmpty;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(99)),
              ),
              Text('Foto de perfil',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).textTheme.titleMedium?.color)),
              const SizedBox(height: 12),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.camera_alt_rounded, color: primary)),
                title: Text('Tirar foto', style: GoogleFonts.inter(fontSize: 14)),
                subtitle: Text('Usar a câmera',
                  style: GoogleFonts.inter(fontSize: 12,
                    color: Theme.of(ctx).textTheme.bodySmall?.color)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.photo_library_rounded, color: primary)),
                title: Text('Escolher da galeria', style: GoogleFonts.inter(fontSize: 14)),
                subtitle: Text('Selecionar uma foto existente',
                  style: GoogleFonts.inter(fontSize: 12,
                    color: Theme.of(ctx).textTheme.bodySmall?.color)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              if (temFoto) ...[
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red)),
                  title: Text('Remover foto',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.red)),
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
              ],
              const SizedBox(height: 8),
            ]),
          ),
        );
      },
    );

    if (!context.mounted) return;

    if (source == null) {
      if (context.read<AppState>().usuarioFoto.isNotEmpty) {
        await context.read<AppState>().setFotoPerfil('');
      }
      return;
    }

    final picked = await picker.pickImage(
      source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked == null || !context.mounted) return;
    final bytes = await picked.readAsBytes();
    final dataUrl = _toDataUrl(bytes, picked.name);
    await context.read<AppState>().setFotoPerfil(dataUrl);
  }

  String _toDataUrl(Uint8List bytes, String filename) {
    final ext  = filename.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final foto    = state.usuarioFoto;
    final nome    = state.usuarioNome;
    final hasPhoto = foto.startsWith('data:');

    Uint8List? bytes;
    if (hasPhoto) {
      bytes = base64Decode(foto.split(',').last);
    }

    Widget avatar = ClipOval(
      child: Container(
        width: size, height: size,
        color: primary.withOpacity(0.12),
        child: hasPhoto && bytes != null
            ? OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.translate(
                  offset: Offset(state.fotoOffsetX, state.fotoOffsetY),
                  child: Transform.scale(
                    scale: state.fotoScale,
                    child: Image.memory(
                      bytes,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            : Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: primary.withOpacity(0.12)),
                child: nome.isNotEmpty
                    ? Text(_iniciais(nome),
                        style: GoogleFonts.inter(
                          fontSize: size * 0.32,
                          fontWeight: FontWeight.w700,
                          color: primary))
                    : Icon(Icons.person_rounded, size: size * 0.5, color: primary),
              ),
      ),
    );

    // Adicionar borda
    avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primary.withOpacity(0.3), width: 1.5),
      ),
      child: avatar,
    );

    if (!editavel) return avatar;

    return GestureDetector(
      onTap: () => _selecionarFoto(context),
      child: Stack(children: [
        avatar,
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: size * 0.34, height: size * 0.34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6)],
            ),
            child: Icon(
              kIsWeb ? Icons.upload_rounded : Icons.camera_alt_rounded,
              size: size * 0.18,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ]),
    );
  }

  String _iniciais(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
