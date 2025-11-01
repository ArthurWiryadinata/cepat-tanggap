class PanduanItem {
  final String teks;
  final String gambar;

  PanduanItem({
    required this.teks,
    required this.gambar,
  });

  factory PanduanItem.fromMap(Map<String, dynamic> map) {
    return PanduanItem(
      teks: map['teks'] ?? '',
      gambar: map['gambar'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teks': teks,
      'gambar': gambar,
    };
  }
}

class PanduanBencana {
  final List<PanduanItem> panduanDalam;
  final List<PanduanItem> panduanLuar;

  PanduanBencana({
    required this.panduanDalam,
    required this.panduanLuar,
  });

  factory PanduanBencana.fromMap(Map<String, dynamic> map) {
    return PanduanBencana(
      panduanDalam: (map['panduan_dalam_ruangan'] as List<dynamic>? ?? [])
          .map((e) => PanduanItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      panduanLuar: (map['panduan_luar_ruangan'] as List<dynamic>? ?? [])
          .map((e) => PanduanItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'panduan_dalam_ruangan': panduanDalam.map((e) => e.toMap()).toList(),
      'panduan_luar_ruangan': panduanLuar.map((e) => e.toMap()).toList(),
    };
  }
}
