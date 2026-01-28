class ThemeOptions {
  final String? name;
  final Map<String, dynamic>? custom;

  const ThemeOptions({this.name, this.custom});

  Map<String, dynamic> toJson() => {'name': ?name, 'custom': ?custom};
}
