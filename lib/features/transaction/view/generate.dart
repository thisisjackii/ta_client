// import 'dart:io';
// import 'dart:ui';

// import 'package:path_provider/path_provider.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

// Future<File> generateExcelAndConvertToPdf() async {
//   final workbook = xlsio.Workbook();
//   final sheet = workbook.worksheets[0]..name = 'Double Entry';

//   final data = [
//     [
//       'Tanggal',
//       'Deskripsi',
//       'Kategori',
//       'Aset',
//       '=',
//       'Liabilitas/Pendapatan/Beban',
//     ],
//     [
//       '1 Apr',
//       'Gajian dari PT Maju Mundur',
//       'Gaji',
//       'Rp 4.000.000',
//       '=',
//       'Pendapatan - Gaji',
//     ],
//     ['', '', '', '', '=', 'Aset - Dompet Digital'],
//     [
//       '2 Apr',
//       'Bayar cicilan motor bulan ini',
//       'Cicilan',
//       'Rp 1.000.000',
//       '=',
//       'Liabilitas - Kredit Motor',
//     ],
//     ['', '', '', '', '=', 'Aset - Dompet Digital'],
//     [
//       '2 Apr',
//       'Beli bakso di Mang Udin',
//       'Makan',
//       'Rp 15.000',
//       '=',
//       'Beban - Makanan & Minuman',
//     ],
//     ['', '', '', '', '=', 'Aset - Dompet Digital'],
//     ['TOTAL', '', '', 'Rp 3.975.000', '', 'Rp 3.975.000'],
//   ];

//   for (var i = 0; i < data.length; i++) {
//     for (var j = 0; j < data[i].length; j++) {
//       sheet.getRangeByIndex(i + 1, j + 1).setText(data[i][j]);
//     }
//   }

//   workbook
//     ..saveAsStream()
//     ..dispose();

//   // Convert Excel to PDF
//   final pdfDoc = PdfDocument();
//   final page = pdfDoc.pages.add();

//   final grid = PdfGrid();
//   grid.columns.add(count: 6);
//   grid.headers.add(1);
//   for (var i = 0; i < data[0].length; i++) {
//     grid.headers[0].cells[i].value = data[0][i];
//   }

//   for (var i = 1; i < data.length; i++) {
//     final row = grid.rows.add();
//     for (var j = 0; j < data[i].length; j++) {
//       row.cells[j].value = data[i][j];
//     }
//   }

//   grid
//     ..style = PdfGridStyle(
//       cellPadding: PdfPaddings(left: 3, right: 3, top: 2, bottom: 2),
//       font: PdfStandardFont(PdfFontFamily.helvetica, 9),
//     )
//     ..draw(page: page, bounds: Rect.zero);

//   final pdfBytes = await pdfDoc.save();
//   pdfDoc.dispose();

//   final dir = await getApplicationDocumentsDirectory();
//   final pdfFile = File('${dir.path}/double_entry_recap.pdf');
//   await pdfFile.writeAsBytes(pdfBytes, flush: true);
//   return pdfFile;
// }
