import 'user.dart';

class DeliveryItem {
  final int id;
  final DateTime createdAt;
  final String photoUrl;
  final String status;
  final String? notes;
  final UserPublic user;

  DeliveryItem({
    required this.id,
    required this.createdAt,
    required this.photoUrl,
    required this.status,
    required this.notes,
    required this.user,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      id: json["id"],
      createdAt: DateTime.parse(json["created_at"]),
      photoUrl: json["photo_url"],
      status: json["status"],
      notes: json["notes"],
      user: UserPublic.fromJson(Map<String, dynamic>.from(json["user"])),
    );
  }
}
