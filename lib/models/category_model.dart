

class CategoryModel {
  final String id;
  final String name; // English name
  final String nameAr; // Arabic name
  final String? icon;
  final String? color;
  final int order;
  final String visibility; // public, vip_only, hidden_for_regular, hidden_for_all

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameAr,
    this.icon,
    this.color,
    this.order = 99,
    this.visibility = 'public',
  });

  // Helper getters
  bool get isPublic => visibility == 'public';
  bool get isVipOnly => visibility == 'vip_only';
  bool get isHiddenForRegular => visibility == 'hidden_for_regular';
  bool get isHiddenForAll => visibility == 'hidden_for_all';
  
  // Helper for UI toggle (simplification: hidden means hidden for all)
  bool get isHidden => visibility == 'hidden_for_all';

  factory CategoryModel.fromSupabase(Map<String, dynamic> data) {
    // Migration fallback: if visibility is null, check is_vip_only
    String visibility = data['visibility'] ?? 'public';
    if (data['visibility'] == null && data['is_vip_only'] == true) {
      visibility = 'vip_only';
    }

    return CategoryModel(
      id: data['id'] ?? '',
      name: data['name_en'] ?? data['name'] ?? '', 
      nameAr: data['name_ar'] ?? data['name'] ?? '',
      icon: data['icon_name'] ?? data['icon'],
      color: data['color'],
      order: data['order'] ?? 99,
      visibility: visibility,
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
      'visibility': visibility,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? icon,
    String? color,
    int? order,
    String? visibility,
    bool? isHidden, // Helper to set visibility
  }) {
    String finalVisibility = visibility ?? this.visibility;
    if (isHidden != null) {
      finalVisibility = isHidden ? 'hidden_for_all' : 'public';
    }

    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      visibility: finalVisibility,
    );
  }
}
