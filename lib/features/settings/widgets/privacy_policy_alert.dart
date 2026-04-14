import 'package:almanca_kelime_testi/helpers/policy/privacy_policy.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyAlert extends StatelessWidget {
  const PrivacyPolicyAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: const Row(
        children: [
          Icon(Icons.privacy_tip_rounded, color: Color(0xFF5D3FD3)),
          SizedBox(width: 10),
          Text("Gizlilik Politikası", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            PrivacyPolicy.content, // Helper sınıfından çekiliyor
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Kapat", style: TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}