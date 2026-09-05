/// Sunucudaki `User` kaydının uygulama içindeki karşılığı.
///
/// Alan adları Türkçe, JSON anahtarları İngilizce. Dönüşüm tek yerde —
/// `fromJson` içinde — yapılır; ekranlar `json['fullName']` gibi ham
/// anahtarlarla uğraşmaz.
class Kullanici {
  final int id;
  final String eposta;
  final String adSoyad;
  final String rol;

  const Kullanici({
    required this.id,
    required this.eposta,
    required this.adSoyad,
    required this.rol,
  });

  /// Rol kontrolü tek yerde tanımlanır. Ekranlarda `rol == 'ADMIN'`
  /// yazılsaydı metin her yerde tekrar ederdi.
  bool get yoneticiMi => rol == 'ADMIN';

  factory Kullanici.fromJson(Map<String, dynamic> json) {
    return Kullanici(
      id: json['id'] as int,
      eposta: json['email'] as String,
      adSoyad: json['fullName'] as String,
      rol: json['role'] as String,
    );
  }
}
