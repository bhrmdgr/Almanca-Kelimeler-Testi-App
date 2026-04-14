import 'package:flutter/material.dart';

class AvatarSelectionView extends StatelessWidget {
  final List<String> avatars = [
    'assets/avatars/boy-avatar-1.png',
    'assets/avatars/boy-avatar-2.png',
    'assets/avatars/boy-avatar-3.png',
    'assets/avatars/boy-avatar-4.png',
    'assets/avatars/girl-avatar-1.png',
    'assets/avatars/girl-avatar-2.png',
    'assets/avatars/girl-avatar-3.png',
    'assets/avatars/girl-avatar-4.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("Avatarını Seç", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text("Seni en iyi temsil eden karakteri seç.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 25),
          GridView.builder(
            shrinkWrap: true,
            itemCount: avatars.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
            ),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, avatars[index]),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF5D3FD3).withOpacity(0.1), width: 2),
                    image: DecorationImage(image: AssetImage(avatars[index])),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}