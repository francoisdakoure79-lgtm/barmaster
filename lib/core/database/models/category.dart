class Category {
  int id;
  String name;
  String icon;
  String color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'] ?? '📦',
      color: json['color'] ?? '#FFFFFF',
    );
  }
}
