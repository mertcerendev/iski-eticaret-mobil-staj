/// Sunucudaki `Category` kaydının karşılığı.
class Kategori {
  final int id;
  final String ad;
  final String slug;
  final String? gorselUrl;

  const Kategori({
    required this.id,
    required this.ad,
    required this.slug,
    this.gorselUrl,
  });

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['id'] as int,
      ad: json['name'] as String,
      slug: json['slug'] as String,
      gorselUrl: json['imageUrl'] as String?,
    );
  }
}
