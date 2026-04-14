import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TargetAlert extends StatefulWidget {
  final int currentGoal;
  final Function(int) onGoalSelected;

  const TargetAlert({
    super.key,
    required this.currentGoal,
    required this.onGoalSelected,
  });

  @override
  State<TargetAlert> createState() => _TargetAlertState();
}

class _TargetAlertState extends State<TargetAlert> {
  late int _selectedGoal;
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> _presetGoals = [
    {'title': 'Rahat', 'value': 10, 'desc': 'Günde 10 kelime'},
    {'title': 'Orta', 'value': 30, 'desc': 'Günde 30 kelime'},
    {'title': 'Ciddi', 'value': 50, 'desc': 'Günde 50 kelime'},
    {'title': 'Yoğun', 'value': 70, 'desc': 'Günde 70 kelime'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoal;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: const Column(
        children: [
          Icon(Icons.track_changes_rounded, color: Color(0xFF5D3FD3), size: 40),
          SizedBox(height: 10),
          Text("Hedefini Güncelle", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Günlük yeni kelime hedefini seç veya kendin belirle.",
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),

            // Hazır Seçenekler
            ..._presetGoals.map((goal) {
              bool isSelected = _selectedGoal == goal['value'];
              return _buildOption(goal, isSelected);
            }),

            const Divider(height: 30),

            // Özel Hedef Girişi
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: "Özel hedef gir (örn: 60)",
                prefixIcon: const Icon(Icons.edit_note_rounded),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() => _selectedGoal = int.parse(value));
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            widget.onGoalSelected(_selectedGoal);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5D3FD3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Güncelle", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildOption(Map<String, dynamic> goal, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = goal['value'];
          _controller.clear();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF5D3FD3) : Colors.grey.shade300, width: 2),
          color: isSelected ? const Color(0xFF5D3FD3).withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(goal['desc'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF5D3FD3)),
          ],
        ),
      ),
    );
  }
}