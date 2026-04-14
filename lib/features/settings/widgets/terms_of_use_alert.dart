import 'package:almanca_kelime_testi/helpers/policy/terms_of_use.dart';
import 'package:flutter/material.dart';

class TermsOfUseAlert extends StatelessWidget {
  const TermsOfUseAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: const Row(
        children: [
          Icon(Icons.description_rounded, color: Color(0xFF5D3FD3)),
          SizedBox(width: 10),
          Text("Kullanım Koşulları", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            TermsOfUse.content, // Helper sınıfından çekiliyor
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Anladım", style: TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}