// lib/core/constants/account_type_mapping.dart
final Map<String, String> categoryToAccountType = {
  // === ASET group ===
  'Kas': 'Aset',
  'Piutang': 'Aset',
  'Bangunan': 'Aset',
  'Tanah': 'Aset',
  'Peralatan': 'Aset',
  'Surat Berharga': 'Aset',
  'Investasi Alternatif': 'Aset',
  'Aset Pribadi': 'Aset',

  // === LIABILITAS group ===
  'Utang': 'Liabilitas',
  'Utang Wesel': 'Liabilitas',
  'Utang Hipotek': 'Liabilitas',

  // === PEMASUKAN group ===
  'Pendapatan dari Pekerjaan': 'Pemasukan',
  'Pendapatan dari Investasi': 'Pemasukan',
  'Pendapatan Bunga': 'Pemasukan',
  'Keuntungan dari Aset': 'Pemasukan',
  'Pendapatan Jasa': 'Pemasukan',

  // === PENGELUARAN group ===
  'Tabungan': 'Pengeluaran',
  'Makanan & Minuman': 'Pengeluaran',
  'Hadiah & Donasi': 'Pengeluaran',
  'Transportasi': 'Pengeluaran',
  'Kesehatan & Medis': 'Pengeluaran',
  'Perawatan Pribadi & Pakaian': 'Pengeluaran',
  'Hiburan & Rekreasi': 'Pengeluaran',
  'Pendidikan & Pembelajaran': 'Pengeluaran',
  'Kewajiban Finansial': 'Pengeluaran',
  'Perumahan dan Kebutuhan Sehari-hari': 'Pengeluaran',

  // === EKUITAS group ===
  'Ekuitas': 'Ekuitas',
};
