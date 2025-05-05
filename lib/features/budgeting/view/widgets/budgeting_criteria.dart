enum OccupationGroup { pelajar, pekerja, suamiIstri }

OccupationGroup getOccupationGroup(String occupation) {
  final normalized = occupation.toLowerCase();
  if (normalized.contains('pelajar') || normalized.contains('mahasiswa')) {
    return OccupationGroup.pelajar;
  } else if (normalized.contains('suami') || normalized.contains('istri')) {
    return OccupationGroup.suamiIstri;
  } else {
    return OccupationGroup.pekerja;
  }
}

const kapoorMinMax = {
  OccupationGroup.pelajar: {
    'Perumahan dan Kebutuhan Sehari-hari': [0, 25],
    'Transportasi': [5, 10],
    'Makanan & Minuman': [15, 20],
    'Perawatan Pribadi & Pakaian': [5, 12],
    'Kesehatan & Medis': [3, 5],
    'Hiburan & Rekreasi': [5, 10],
    'Pendidikan & Pembelajaran': [10, 30],
    'Kewajiban Finansial (pinjaman, pajak, asuransi)': [0, 5],
    'Hadiah & Donasi': [4, 6],
    'Tabungan': [0, 10],
  },
  OccupationGroup.pekerja: {
    'Perumahan dan Kebutuhan Sehari-hari': [30, 35],
    'Transportasi': [15, 20],
    'Makanan & Minuman': [15, 25],
    'Perawatan Pribadi & Pakaian': [5, 15],
    'Kesehatan & Medis': [3, 5],
    'Hiburan & Rekreasi': [5, 10],
    'Pendidikan & Pembelajaran': [2, 4],
    'Kewajiban Finansial (pinjaman, pajak, asuransi)': [4, 8],
    'Hadiah & Donasi': [5, 8],
    'Tabungan': [4, 15],
  },
  OccupationGroup.suamiIstri: {
    'Perumahan dan Kebutuhan Sehari-hari': [25, 35],
    'Transportasi': [15, 20],
    'Makanan & Minuman': [15, 25],
    'Perawatan Pribadi & Pakaian': [5, 10],
    'Kesehatan & Medis': [4, 10],
    'Hiburan & Rekreasi': [4, 8],
    'Pendidikan & Pembelajaran': [3, 5],
    'Kewajiban Finansial (pinjaman, pajak, asuransi)': [5, 9],
    'Hadiah & Donasi': [3, 5],
    'Tabungan': [5, 10],
  },
};
