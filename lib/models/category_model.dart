

class CategoryModel {
  final String id;
  final String name; // English name
  final String nameAr; // Arabic name
  final String? icon;
  final String? color;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameAr,
    this.icon,
    this.color,
    this.order = 99,
  });

  factory CategoryModel.fromSupabase(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id'] ?? '',
      name: data['name_en'] ?? data['name'] ?? '', 
      nameAr: data['name_ar'] ?? data['name'] ?? '',
      icon: data['icon_name'] ?? data['icon'],
      color: data['color'],
      order: data['order'] ?? 99,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_en': name,
      'name_ar': nameAr,
      'icon_name': icon,
      'color': color,
      'order': order,
    };
  }
}
