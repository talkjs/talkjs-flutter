class ThemeOptions {
  final String? name;
  final Map<String, dynamic>? custom;

  const ThemeOptions({this.name, this.custom});

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    if (name != null) {
      result['name'] = name;
      result['custom'] = custom;
    } else {
      result['custom'] = custom;
    }
    return result;
  }
}
