import 'package:cloud_firestore/cloud_firestore.dart';

class HelpRequest {
  final String userId;
  final String username;
  final String email;
  final String phoneNumber;
  final String message;
  final String reply;     // ✅ Yeni: Yönetici cevabı
  final String status;    // ✅ Yeni: Talebin durumu (Açık, Cevaplandı, Kapandı vb.)
  final DateTime timestamp;

  HelpRequest({
    required this.userId,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.message,
    required this.reply,
    required this.status,
    required this.timestamp,
  });

  // Firebase'e veri gönderirken
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'message': message,
      'reply': reply, // Başlangıçta boş string gidecek
      'status': status, // Başlangıçta "Açık" gidecek
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // ✅ Yeni: Firebase'den veri okurken (Taleplerim listesi için gerekli)
  factory HelpRequest.fromMap(Map<String, dynamic> map) {
    return HelpRequest(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      message: map['message'] ?? '',
      reply: map['reply'] ?? '',
      status: map['status'] ?? 'Açık',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}