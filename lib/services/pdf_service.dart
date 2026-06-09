// lib/services/pdf_service.dart
// Gera PDFs dos cálculos com logo, dados do advogado e resultados.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Paleta do app
const _navy      = PdfColor(0.043, 0.063, 0.094);  // #0B1018
const _gold      = PdfColor(0.788, 0.663, 0.380);  // #C9A961
const _goldLight = PdfColor(0.941, 0.831, 0.533);  // #F0D488
const _cream     = PdfColor(0.957, 0.933, 0.859);  // #F3EEDB
const _grey      = PdfColor(0.4, 0.4, 0.4);
const _lightGrey = PdfColor(0.94, 0.94, 0.94);

class PdfService {
  /// Abre o diálogo de impressão/salvar com o PDF gerado.
  static Future<void> gerarEImprimir({
    required String titulo,
    required String subtitulo,
    required List<_SecaoPdf> secoes,
    required String nome,
    required String oab,
    required String fotoBase64, // data URL ou vazio
    required String modoCalculo,
  }) async {
    final doc = pw.Document();

    // Decodifica logo se existir
    pw.MemoryImage? logoImg;
    if (fotoBase64.isNotEmpty && fotoBase64.contains(',')) {
      try {
        final bytes = base64Decode(fotoBase64.split(',').last);
        logoImg = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildHeader(titulo, subtitulo, nome, oab, logoImg, modoCalculo),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final s in secoes) ...[
                    _buildSecao(s),
                    pw.SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '${titulo.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // ── Header ──────────────────────────────────────────────────
  static pw.Widget _buildHeader(
    String titulo, String subtitulo,
    String nome, String oab,
    pw.MemoryImage? logo, String modo,
  ) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo
          if (logo != null)
            pw.Container(
              width: 56, height: 56,
              decoration: pw.BoxDecoration(
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 8, verticalRadius: 8,
                child: pw.Image(logo, width: 56, height: 56, fit: pw.BoxFit.cover),
              ),
            )
          else
            pw.Container(
              width: 56, height: 56,
              decoration: pw.BoxDecoration(
                color: _gold.shade(0.3),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text('CP',
                style: pw.TextStyle(
                  color: _goldLight,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                )),
            ),
          pw.SizedBox(width: 16),
          // Título e advogado
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CALCULADORA PENAL',
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: 9,
                    letterSpacing: 2.5,
                    fontWeight: pw.FontWeight.bold,
                  )),
                pw.SizedBox(height: 4),
                pw.Text(titulo,
                  style: pw.TextStyle(
                    color: _cream,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  )),
                pw.SizedBox(height: 2),
                pw.Text(subtitulo,
                  style: pw.TextStyle(color: _gold, fontSize: 11)),
              ],
            ),
          ),
          // Dados do advogado
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (nome.isNotEmpty)
                pw.Text(nome,
                  style: pw.TextStyle(
                    color: _cream,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  )),
              if (oab.isNotEmpty)
                pw.Text('OAB $oab',
                  style: pw.TextStyle(color: _gold, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                style: pw.TextStyle(color: _grey, fontSize: 9),
              ),
              pw.Text('Modo: $modo',
                style: pw.TextStyle(color: _grey, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Seção ────────────────────────────────────────────────────
  static pw.Widget _buildSecao(_SecaoPdf s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Título da seção
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: pw.BoxDecoration(
            color: _gold,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(s.titulo.toUpperCase(),
            style: pw.TextStyle(
              color: _navy,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            )),
        ),
        pw.SizedBox(height: 8),
        // Itens em grid
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: s.itens.map((item) => _buildItem(item)).toList(),
        ),
        // Observação (opcional)
        if (s.obs != null) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _lightGrey,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: _gold.shade(0.4), width: 0.5),
            ),
            child: pw.Text(s.obs!,
              style: pw.TextStyle(color: _grey, fontSize: 9, lineSpacing: 2)),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildItem(_ItemPdf item) {
    return pw.Container(
      width: item.largura,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _gold.shade(0.3), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(item.label,
            style: pw.TextStyle(color: _grey, fontSize: 8,
              fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
          pw.SizedBox(height: 3),
          pw.Text(item.valor,
            style: pw.TextStyle(
              color: _navy,
              fontSize: item.destaque ? 16 : 12,
              fontWeight: item.destaque
                  ? pw.FontWeight.bold : pw.FontWeight.normal,
            )),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────
  static pw.Widget _buildFooter() {
    return pw.Container(
      color: _navy.shade(0.6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Calculadora Penal — Uso exclusivo do advogado',
            style: pw.TextStyle(color: _grey, fontSize: 8)),
          pw.Text('Este documento não substitui parecer jurídico.',
            style: pw.TextStyle(color: _grey, fontSize: 8)),
        ],
      ),
    );
  }
}

// ── Modelos de dados para o PDF ──────────────────────────────

class PdfSecao {
  final String titulo;
  final List<_ItemPdf> itens;
  final String? obs;
  PdfSecao({required this.titulo, required this.itens, this.obs});
}

class PdfItem {
  final String label;
  final String valor;
  final bool destaque;
  final double largura;
  PdfItem({
    required this.label,
    required this.valor,
    this.destaque = false,
    this.largura = 140,
  });
}

// ── Funções públicas por tela ────────────────────────────────

class PdfConverter {
  static Future<void> gerar({
    required String anos,
    required String meses,
    required String dias,
    required String totalDias,
    required String totalMeses,
    required String totalAnos,
    required String formula,
    required String modoCalculo,
    required String nome,
    required String oab,
    required String foto,
  }) =>
      PdfService.gerarEImprimir(
        titulo: 'Conversão de Pena',
        subtitulo: 'Cálculo de equivalência entre unidades de tempo',
        modoCalculo: modoCalculo,
        nome: nome, oab: oab, fotoBase64: foto,
        secoes: [
          PdfSecao(
            titulo: 'Resultado decomposto',
            itens: [
              PdfItem(label: 'ANOS',  valor: anos,  destaque: true,  largura: 150),
              PdfItem(label: 'MESES', valor: meses, destaque: true,  largura: 150),
              PdfItem(label: 'DIAS',  valor: dias,  destaque: true,  largura: 150),
            ],
          ),
          PdfSecao(
            titulo: 'Totais',
            itens: [
              PdfItem(label: 'TOTAL EM DIAS',  valor: totalDias,  largura: 150),
              PdfItem(label: 'TOTAL EM MESES', valor: totalMeses, largura: 150),
              PdfItem(label: 'TOTAL EM ANOS',  valor: totalAnos,  largura: 150),
            ],
            obs: formula,
          ),
        ],
      );
}

class PdfProjecao {
  static Future<void> gerar({
    required String dataInicio,
    required String pena,
    required String dataTermino,
    required String diaSemana,
    required String totalDias,
    required String fracao,
    required String dataFracao,
    required String detalhes,
    required String modoCalculo,
    required String nome,
    required String oab,
    required String foto,
  }) =>
      PdfService.gerarEImprimir(
        titulo: 'Projeção de Data',
        subtitulo: 'Cálculo da data de término da pena',
        modoCalculo: modoCalculo,
        nome: nome, oab: oab, fotoBase64: foto,
        secoes: [
          PdfSecao(
            titulo: 'Dados de entrada',
            itens: [
              PdfItem(label: 'DATA DE INÍCIO', valor: dataInicio, largura: 200),
              PdfItem(label: 'PENA',           valor: pena,       largura: 200),
            ],
          ),
          PdfSecao(
            titulo: 'Resultado',
            itens: [
              PdfItem(label: 'DATA DE TÉRMINO', valor: dataTermino, destaque: true, largura: 200),
              PdfItem(label: 'DIA DA SEMANA',   valor: diaSemana,   largura: 150),
              PdfItem(label: 'TOTAL EM DIAS',   valor: totalDias,   largura: 150),
              if (fracao.isNotEmpty)
                PdfItem(label: 'FRAÇÃO ($fracao)', valor: dataFracao, largura: 200),
            ],
            obs: detalhes,
          ),
        ],
      );
}

class PdfEntreDatas {
  static Future<void> gerar({
    required String dataInicio,
    required String dataFim,
    required String anos,
    required String meses,
    required String dias,
    required String totalDias,
    required String totalMeses,
    required String detalhes,
    required String modoCalculo,
    required String nome,
    required String oab,
    required String foto,
  }) =>
      PdfService.gerarEImprimir(
        titulo: 'Período Entre Datas',
        subtitulo: 'Cálculo do período entre duas datas',
        modoCalculo: modoCalculo,
        nome: nome, oab: oab, fotoBase64: foto,
        secoes: [
          PdfSecao(
            titulo: 'Datas',
            itens: [
              PdfItem(label: 'DATA INICIAL', valor: dataInicio, largura: 220),
              PdfItem(label: 'DATA FINAL',   valor: dataFim,    largura: 220),
            ],
          ),
          PdfSecao(
            titulo: 'Resultado',
            itens: [
              PdfItem(label: 'ANOS',           valor: anos,       destaque: true, largura: 140),
              PdfItem(label: 'MESES',          valor: meses,      destaque: true, largura: 140),
              PdfItem(label: 'DIAS',           valor: dias,       destaque: true, largura: 140),
              PdfItem(label: 'TOTAL EM DIAS',  valor: totalDias,  largura: 200),
              PdfItem(label: 'TOTAL EM MESES', valor: totalMeses, largura: 200),
            ],
            obs: detalhes,
          ),
        ],
      );
}
