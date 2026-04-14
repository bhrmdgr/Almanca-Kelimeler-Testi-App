import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HelpViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isGuest {
    final user = _auth.currentUser;
    return user == null || user.isAnonymous;
  }

  // Talepleri anlık dinlemek için Stream
  Stream<QuerySnapshot> get myRequests {
    final uid = _auth.currentUser?.uid ?? "";
    return _firestore
        .collection('help')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<bool> sendHelpRequest(String message) async {
    if (message.trim().isEmpty) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      await _firestore.collection('help').add({
        'userId': user.uid,
        'username': userData['username'] ?? 'Bilinmiyor',
        'email': userData['email'] ?? user.email ?? 'E-posta yok',
        'phoneNumber': userData['phoneNumber'] ?? 'Telefon yok',
        'message': message,
        'reply': "", // Başlangıçta boş cevap
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Açık',
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}