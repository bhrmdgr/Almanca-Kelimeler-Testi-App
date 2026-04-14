import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationAlert extends StatefulWidget {
  const NotificationAlert({super.key});

  @override
  State<NotificationAlert> createState() => _NotificationAlertState();
}

class _NotificationAlertState extends State<NotificationAlert> {
  bool _isNotificationEnabled = true;
  bool _isSoundEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isNotificationEnabled = prefs.getBool('notifications_enabled') ?? true;
        _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
        _isLoading = false;
      });
    }
  }

  // ✅ İyimser Güncelleme (Optimistic Update) Metodu
  Future<void> _updateSetting(String key, bool newValue) async {
    // 1. UI'ı anında güncelle (Hiç bekleme yok)
    setState(() {
      if (key == 'notifications_enabled') {
        _isNotificationEnabled = newValue;
      } else if (key == 'sound_enabled') {
        _isSoundEnabled = newValue;
      }
    });

    try {
      // 2. Arka plan işlemlerini başlat
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, newValue);

      if (key == 'notifications_enabled') {
        if (newValue) {
          await FirebaseMessaging.instance.subscribeToTopic("daily_reminders");
          await _updateFirebaseNotificationStatus(true);
          await _restoreFcmToken();
        } else {
          await FirebaseMessaging.instance.unsubscribeFromTopic("daily_reminders");
          await _updateFirebaseNotificationStatus(false);
          await _deleteFcmToken();
        }
      }
    } catch (e) {
      debugPrint("Hata oluştu, ayar geri alınıyor: $e");
      // 3. Hata olursa UI'ı eski haline döndür (Rollback)
      if (mounted) {
        setState(() {
          if (key == 'notifications_enabled') {
            _isNotificationEnabled = !newValue;
          } else if (key == 'sound_enabled') {
            _isSoundEnabled = !newValue;
          }
        });

        // Kullanıcıya çaktırmadan bir uyarı verilebilir (opsiyonel)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ayar güncellenirken bir hata oluştu.")),
        );
      }
    }
  }

  // --- Yardımcı Firebase Metotları (Aynı kaldı) ---
  Future<void> _updateFirebaseNotificationStatus(bool status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'notifications_active': status});
  }

  Future<void> _deleteFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseMessaging.instance.deleteToken();
    await FirebaseFirestore.instance.collection('fcm_tokens').doc(user.uid).delete();
  }

  Future<void> _restoreFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('fcm_tokens').doc(user.uid).set({
      'token': token,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: const Column(
        children: [
          Icon(Icons.notifications_active_rounded, color: Color(0xFF5D3FD3), size: 40),
          SizedBox(height: 10),
          Text("Tercihler", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitchTile(
            title: "Bildirimler",
            subtitle: "Günlük hatırlatıcılar ve uyarılar",
            value: _isNotificationEnabled,
            icon: Icons.notifications_none_rounded,
            onChanged: (val) => _updateSetting('notifications_enabled', val),
          ),
          const Divider(),
          _buildSwitchTile(
            title: "Uygulama İçi Sesler",
            subtitle: "Kelime seslendirme ve efektler",
            value: _isSoundEnabled,
            icon: Icons.volume_up_rounded,
            onChanged: (val) => _updateSetting('sound_enabled', val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Kapat", style: TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF5D3FD3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF5D3FD3), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      value: value,
      activeColor: const Color(0xFF5D3FD3),
      onChanged: onChanged,
    );
  }
}