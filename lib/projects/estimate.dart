import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:prodecor/common/format.dart';
import 'package:prodecor/core/models.dart';

/// Смета для клиента — PDF: печать, сохранение или отправка в мессенджер
Future<void> shareEstimate({required Project p, required Client? client, required Me me}) async {
  final regular = await PdfGoogleFonts.onestRegular();
  final bold = await PdfGoogleFonts.onestBold();
  const ink = PdfColor.fromInt(0xFF1E1D1B), muted = PdfColor.fromInt(0xFF77716A), line = PdfColor.fromInt(0xFFE2DCCF);
  const dark = PdfColor.fromInt(0xFF222321), sand = PdfColor.fromInt(0xFFC9B394);
  final items = p.items ?? [];
  final total = items.fold<double>(0.0, (a, i) => a + i.price * i.qty);
  final now = DateTime.now();
  final date = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  String m(double v) => money(v).replaceAll(' ', ' ');

  pw.Widget logo() => pw.SizedBox(
    width: 30,
    height: 30,
    child: pw.Stack(
      children: [
        pw.Positioned(left: 0, top: 0, child: pw.Container(width: 15, height: 15, color: dark)),
        pw.Positioned(left: 15, top: 0, child: pw.Container(width: 15, height: 15, color: sand)),
        pw.Positioned(left: 0, top: 15, child: pw.Container(width: 15, height: 15, color: sand)),
        pw.Positioned(left: 15, top: 15, child: pw.Container(width: 15, height: 15, color: dark)),
      ],
    ),
  );

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            logo(),
            pw.SizedBox(width: 10),
            pw.Text(
              'PRODECOR',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: ink),
            ),
            pw.Spacer(),
            pw.Text(
              'Дата: $date\nДизайнер: ${me.name}${me.studio.isNotEmpty ? ', ${me.studio}' : ''}\n${me.phone}',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 9, color: muted),
            ),
          ],
        ),
        pw.SizedBox(height: 22),
        pw.Text(
          'Смета · ${p.name}',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: ink),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Клиент: ${client?.name ?? ''}${p.address.isNotEmpty ? ' · ${p.address}' : ''}',
          style: const pw.TextStyle(fontSize: 10, color: muted),
        ),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: line),
            bottom: pw.BorderSide(color: line),
          ),
          headerStyle: pw.TextStyle(fontSize: 8, color: muted, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9.5, color: ink),
          headerDecoration: const pw.BoxDecoration(),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FixedColumnWidth(22),
            1: const pw.FlexColumnWidth(5),
            2: const pw.FlexColumnWidth(1.4),
            3: const pw.FlexColumnWidth(1.6),
            4: const pw.FlexColumnWidth(1.8),
          },
          headers: ['№', 'ТОВАР', 'КОЛ-ВО', 'ЦЕНА', 'СУММА'],
          data: [
            for (var n = 0; n < items.length; n++)
              [
                '${n + 1}',
                items[n].name + (items[n].article.isNotEmpty ? '\nарт. ${items[n].article}' : ''),
                '${num2(items[n].qty).replaceAll(' ', ' ')} ${items[n].measure}',
                m(items[n].price),
                m(items[n].price * items[n].qty),
              ],
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Итого  ', style: const pw.TextStyle(fontSize: 11, color: muted)),
            pw.Text(
              m(total),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: ink),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Цены розничные, актуальны на дату сметы. Наличие и сроки поставки уточняет менеджер.',
          style: const pw.TextStyle(fontSize: 9, color: muted),
        ),
      ],
    ),
  );
  final name = 'Смета ${p.name}'.replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ');
  await Printing.sharePdf(bytes: await doc.save(), filename: '$name.pdf');
}
