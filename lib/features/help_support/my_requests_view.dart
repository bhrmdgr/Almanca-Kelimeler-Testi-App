import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'help_view_model.dart';

class MyRequestsView extends StatelessWidget {
  const MyRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text("Destek Taleplerim",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Consumer<HelpViewModel>(
        builder: (context, viewModel, child) {
          return StreamBuilder<QuerySnapshot>(
            stream: viewModel.myRequests,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF5D3FD3)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: snapshot.data!.docs.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return _buildRequestCard(context, data);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speaker_notes_off_rounded, size: 70, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 15),
          const Text("Henüz bir talebiniz bulunmuyor.",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> data) {
    bool isReplied = data['reply'] != null && data['reply'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ListTile(
          onTap: () => _showRequestDetail(context, data),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isReplied ? const Color(0xFFE8F5E9) : const Color(0xFFF3E5F5),
            child: Icon(
              isReplied ? Icons.done_all_rounded : Icons.hourglass_empty_rounded,
              color: isReplied ? const Color(0xFF2E7D32) : const Color(0xFF5D3FD3),
              size: 20,
            ),
          ),
          title: Text(
            data['message'] ?? "Mesaj yok",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                _buildStatusBadge(isReplied ? "Cevaplandı" : "Beklemede", isReplied),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(data['timestamp']),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFF5D3FD3),
        ),
      ),
    );
  }

  void _showRequestDetail(BuildContext context, Map<String, dynamic> data) {
    bool isReplied = data['reply'] != null && data['reply'].toString().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            const Text("Talep Detayı", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),

            _detailRow("Mesajınız", data['message'], Icons.chat_bubble_outline_rounded, const Color(0xFF5D3FD3)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
            _detailRow(
                "Ekibimizin Cevabı",
                isReplied ? data['reply'] : "Mesajınız alındı, en kısa sürede inceleyip size buradan bilgi vereceğiz.",
                Icons.auto_awesome_rounded,
                isReplied ? const Color(0xFF00B09B) : Colors.grey,
                isItalic: !isReplied
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3FD3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 15)
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Anladım", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String content, IconData icon, Color color, {bool isItalic = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(content, style: TextStyle(fontSize: 14, height: 1.4, fontStyle: isItalic ? FontStyle.italic : FontStyle.normal)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Az önce";
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    }
    return "";
  }
}