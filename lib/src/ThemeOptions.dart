import 'dart:convert';

class ThemeOptions {
  final String? theme;
  final Map<String, String?>? custom;

  const ThemeOptions(this.theme, this.custom);

  String getJsonString() {
    final result = <String, dynamic>{};
    if (theme != null) {
      result["theme"] = theme;
      result["custom"] = custom;
    } else {
      result["custom"] = custom;
    }
    return json.encode(result);
  }
}
