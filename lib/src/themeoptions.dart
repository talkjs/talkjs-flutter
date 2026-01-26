class ThemeOptions {
  final String? name;
  final Map<String, dynamic>? custom;

  const ThemeOptions({this.name, this.custom});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    if (name != null) {
      result['name'] = name;
    }
    if (custom != null) {
      result['custom'] = custom;
    }
    return result;
  }
}
