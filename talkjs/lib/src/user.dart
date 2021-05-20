/// A user of your app.
///
/// TalkJS uses the [id] to uniquely identify this user. All other fields of a
/// [User] are allowed to vary over time and the TalkJS database will update its
/// fields accordingly.
class User {
  /// The default message a user sees when starting a chat with this person.
  ///
  /// This acts similarly to [welcomeMessage] with the difference being that
  /// this appears as a system message.
  String? availabilityText;

  /// Custom metadata for this user.
  Map<String, String?>? custom;

  /// One or more email address belonging to this user.
  ///
  /// The email addresses will be used for [Email Notifications](https://talkjs.com/docs/Features/Notifications/Email_Notifications/index.html)
  /// if they are enabled.
  List<String>? email;

  /// One or more phone numbers belonging to this user.
  ///
  /// The phone numbers will be used for [SMS Notifications](https://talkjs.com/docs/Features/Notifications/SMS_Notifications.html).
  /// This feature requires standard plan and up.
  List<String>? phone;

  /// The unique user identifier.
  String id;

  /// This user's name which will be displayed on the TalkJS UI
  String name;

  /// The language on the UI.
  ///
  /// This field expects an [IETF language tag](https://www.w3.org/International/articles/language-tags/).
  String? locale;

  /// An optional URL to a photo which will be displayed as this user's avatar
  String? photoUrl;

  /// This user's role which allows you to change the behaviour of TalkJS for
  /// different users.
  String? role;

  /// The default message a user sees when starting a chat with this person.
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