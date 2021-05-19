class User {
  String? availabilityText;
  Map<String, String?>? custom;

  List<String>? email;
  List<String>? phone;

  String id;
  String name;

  String? locale;
  String? photoUrl;

  String? role;
  String? welcomeMessage;

  User({required this.id, required this.name, this.email, this.phone,
    this.availabilityText, this.locale, this.photoUrl, this.role, this.custom,
    this.welcomeMessage
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'availabilityText': availabilityText,
    'locale': locale,
    'photoUrl': photoUrl,
    'role': role,
    'welcomeMessage': welcomeMessage,
    'custom': custom
  };
}