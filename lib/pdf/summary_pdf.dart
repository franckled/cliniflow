import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/project.dart';
import '../engine/engine.dart';
import '../ui/credit.dart' show Credit;

const _ink = PdfColor.fromInt(0xFF12324A);
const _muted = PdfColor.fromInt(0xFF5B6670);
const _line = PdfColor.fromInt(0xFFD5DCE2);

PdfColor _familyColor(CategoryFamily f) => switch (f) {
      CategoryFamily.high => const PdfColor.fromInt(0xFFB3261E),
      CategoryFamily.medium => const PdfColor.fromInt(0xFF9A5B00),
      CategoryFamily.low => const PdfColor.fromInt(0xFF2E6B3A),
      CategoryFamily.drug => const PdfColor.fromInt(0xFF6A3FA0),
      CategoryFamily.device => const PdfColor.fromInt(0xFF00658E),
      CategoryFamily.data => const PdfColor.fromInt(0xFF4A5A6A),
      CategoryFamily.neutral => const PdfColor.fromInt(0xFF5F5E62),
    };

String _fileName(Project p) {
  final base = p.displayName
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return 'CliniFlow_${base.isEmpty ? 'projet' : base}.pdf';
}

Future<void> sharePdf(Project p) async {
  final bytes = await buildSummaryPdf(p);
  await Printing.sharePdf(bytes: bytes, filename: _fileName(p));
}

Future<void> printPdf(Project p) async {
  await Printing.layoutPdf(
    name: _fileName(p),
    onLayout: (_) => buildSummaryPdf(p),
  );
}

/// Construit la fiche de synthèse. Les polices DejaVu sont embarquées pour
/// couvrir tous les caractères français (œ, guillemets, tirets).
Future<Uint8List> buildSummaryPdf(Project p, {DateTime? now}) async {
  final c = p.classification;
  if (c == null) throw StateError('Projet non qualifié');
  final date = now ?? DateTime.now();

  final regular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
  final bold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));
  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/icon/logo_mark.png')).buffer.asUint8List(),
  );

  final doc = pw.Document(
    title: 'CliniFlow – ${p.displayName}',
    author: p.sponsor.isEmpty ? 'CliniFlow' : p.sponsor,
    creator: 'CliniFlow',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  final accent = _familyColor(c.category.family);
  final steps = p.steps;
  final progress = p.progress;

  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(text,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            )),
      );

  pw.Widget bullet(String text, String mark) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 14, child: pw.Text(mark)),
            pw.Expanded(
                child: pw.Text(text, style: const pw.TextStyle(lineSpacing: 2))),
          ],
        ),
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 48),
      theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
            defaultTextStyle: const pw.TextStyle(fontSize: 9.5, color: _ink),
          ),
      footer: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(Credit.oneLine,
              style: pw.TextStyle(
                fontSize: 7.5,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 2),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Aide à la décision – la qualification définitive relève du '
                  'promoteur et, le cas échéant, du CPP.',
                  style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                ),
              ),
              pw.Text('${ctx.pageNumber}/${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
            ],
          ),
        ],
      ),
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 12, bottom: 2),
              child: pw.Image(logo, width: 38, height: 38),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FICHE DE QUALIFICATION RÉGLEMENTAIRE',
                      style: pw.TextStyle(
                        fontSize: 8,
                        letterSpacing: 1.2,
                        color: _muted,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.SizedBox(height: 4),
                  pw.Text(p.displayName,
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  if (p.acronym.isNotEmpty && p.title.isNotEmpty)
                    pw.Text(p.title, style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.Text('Éditée le ${formatDate(date)}',
                style: const pw.TextStyle(color: _muted)),
          ],
        ),
        if (p.sponsor.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text('Promoteur : ${p.sponsor}'),
          ),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: accent, width: 4)),
            color: PdfColor(accent.red, accent.green, accent.blue, 0.07),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(c.category.label,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  )),
              pw.SizedBox(height: 2),
              pw.Text(c.category.framework),
            ],
          ),
        ),
        heading('Justification'),
        for (final r in c.reasons) bullet(r, '✓'),
        if (c.toConfirm.isNotEmpty) ...[
          heading('Points à confirmer'),
          for (final r in c.toConfirm) bullet(r, '!'),
        ],
        heading('Parcours réglementaire – '
            '${progress.done}/${progress.total} étapes soldées'),
        pw.TableHelper.fromTextArray(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
            bottom: pw.BorderSide(color: _line, width: 0.5),
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFEFF3F6),
          ),
          headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.6),
            1: pw.FlexColumnWidth(4),
            2: pw.FlexColumnWidth(1.7),
            3: pw.FlexColumnWidth(1.3),
            4: pw.FlexColumnWidth(1.2),
          },
          headers: const ['Phase', 'Étape', 'Instance', 'Statut', 'Échéance'],
          data: [
            for (final s in steps)
              [
                s.phase.label,
                s.title,
                s.actor ?? '',
                p.trackingFor(s.id).status.label,
                switch (p.trackingFor(s.id).dueDate) {
                  final d? => formatDate(d),
                  null => s.delay ?? '',
                },
              ],
          ],
        ),
        if (steps.any((s) => p.trackingFor(s.id).note.isNotEmpty)) ...[
          heading('Notes'),
          for (final s in steps)
            if (p.trackingFor(s.id).note.isNotEmpty)
              bullet('${s.title} : ${p.trackingFor(s.id).note}', '•'),
        ],
      ],
    ),
  );

  return doc.save();
}
