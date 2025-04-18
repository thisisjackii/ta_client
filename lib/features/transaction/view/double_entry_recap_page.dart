import 'package:flutter/material.dart';
// import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class DoubleEntryRecapPage extends StatelessWidget {
  const DoubleEntryRecapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        // padding: const EdgeInsets.all(8),
        // child: TableView(
        //   // Define columns
        //   columns: [
        //     TableColumn(width: 150), // Tanggal
        //     TableColumn(width: 100), // Waktu
        //     TableColumn(width: 150), // Kategori
        //     TableColumn(width: 150), // Aset
        //     TableColumn(width: 100), // Liabilitas
        //     TableColumn(width: 150), // Pendapatan (+)
        //     TableColumn(width: 150), // Beban (-)
        //   ],
        //   // Define rows with spans
        //   rows: [
        //     // Header Row 1
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 0, column: 0),
        //           rowspan: 2,
        //           colspan: 4,
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('Tanggal'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 0, column: 4),
        //           rowspan: 2,
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('Liabilitas'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 0, column: 5),
        //           rowspan: 1,
        //           colspan: 2,
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('Ekuitas'),
        //           ),
        //         ),
        //       ],
        //     ),
        //     // Header Row 2
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 1, column: 0),
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('Waktu'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 1, column: 1),
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('Kategori'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 1, column: 2),
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('Aset'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 1, column: 3),
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('='),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 1, column: 4),
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 1, column: 5),
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('Pendapatan (+)'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 1, column: 6),
        //           child: Container(
        //             color: Colors.blue[200],
        //             alignment: Alignment.center,
        //             child: const Text('Beban (-)'),
        //           ),
        //         ),
        //       ],
        //     ),
        //     // Data Rows
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 2, column: 0),
        //           rowspan: 4,
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('24/03/2025'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 2, column: 1),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('10:00:01'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 2, column: 2),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('Makanan'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 2, column: 3),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('10.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 2, column: 4),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 2, column: 5),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('10.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 2, column: 6),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //       ],
        //     ),
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 3, column: 1),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('12:13:54'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 3, column: 2),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('Minuman'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 3, column: 3),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('8.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 3, column: 4),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 3, column: 5),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('8.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 3, column: 6),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //       ],
        //     ),
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 4, column: 1),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('21:01:39'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 4, column: 2),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('Transportasi'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 4, column: 3),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('-500.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 4, column: 4),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 4, column: 5),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 4, column: 6),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('500.000'),
        //           ),
        //         ),
        //       ],
        //     ),
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 5, column: 1),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('23:23:17'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 5, column: 2),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('Minuman'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 5, column: 3),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('-2.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 5, column: 4),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 5, column: 5),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 5, column: 6),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('2.000.000'),
        //           ),
        //         ),
        //       ],
        //     ),
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 6, column: 0),
        //           rowspan: 3,
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('25/03/2025'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 6, column: 1),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('03:21:10'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 6, column: 2),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('Liburan'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 6, column: 3),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('3.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 6, column: 4),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 6, column: 5),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('3.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 6, column: 6),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //       ],
        //     ),
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 7, column: 1),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('08:10:59'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 7, column: 2),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('Makanan'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 7, column: 3),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('5.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 7, column: 4),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 7, column: 5),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('5.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 7, column: 6),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //       ],
        //     ),
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 8, column: 1),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('18:43:29'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 8, column: 2),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('Kesehatan'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 8, column: 3),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('-2.000.000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 8, column: 4),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 8, column: 5),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text(''),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 8, column: 6),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('2.000.000'),
        //           ),
        //         ),
        //       ],
        //     ),
        //     // Total Row
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 9, column: 0),
        //           rowspan: 2,
        //           colspan: 4,
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('Total'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 9, column: 4),
        //           rowspan: 2,
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('5000000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 9, column: 5),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('21000000'),
        //           ),
        //         ),
        //         TableCell(
        //           vicinity: const TableVicinity(row: 9, column: 6),
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('4500000'),
        //           ),
        //         ),
        //       ],
        //     ),
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 10, column: 5),
        //           colspan: 2,
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('16500000'),
        //           ),
        //         ),
        //       ],
        //     ),
        //     // Grand Total Row
        //     TableRow(
        //       cells: [
        //         TableCell(
        //           vicinity: const TableVicinity(row: 11, column: 5),
        //           colspan: 2,
        //           child: Container(
        //             alignment: Alignment.center,
        //             child: const Text('21500000'),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
        );
  }
}
