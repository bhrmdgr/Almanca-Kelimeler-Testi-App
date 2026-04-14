import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'help_view_model.dart';
import 'my_requests_view.dart'; // Önceki mesajda oluşturduğumuz liste sayfası

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => HelpViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: AppBar(
          title: const Text("Yardım ve Destek", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionButtons(context), // Güncellendi: İki buton içeren yapı
              const SizedBox(height: 30),
              _buildHelpTitle("Sıkça Sorulan Sorular"),
              const SizedBox(height: 15),
              _buildHelpContent(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Üstteki Buton Grubu ---
  // --- Üstteki Buton Grubu (GÜNCELLENDİ) ---
  Widget _buildActionButtons(BuildContext context) {
    final viewModel = context.read<HelpViewModel>(); // ViewModel'e eriştik

    return Column(
      children: [
        _buildGradientButton(
          context: context,
          text: "Bize Ulaşın",
          icon: Icons.support_agent_rounded,
          onPressed: () {
            if (viewModel.isGuest) {
              _showGuestWarning(context);
            } else {
              _showSupportDialog(context);
            }
          },
          colors: [const Color(0xFF5D3FD3), const Color(0xFF8E2DE2)],
        ),
        const SizedBox(height: 12),
        _buildGradientButton(
          context: context,
          text: "Destek Taleplerim",
          icon: Icons.history_rounded,
          onPressed: () {
            if (viewModel.isGuest) {
              _showGuestWarning(context);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyRequestsView()),
              );
            }
          },
          colors: [const Color(0xFF2D3142), const Color(0xFF4F5D75)],
        ),
      ],
    );
  }

  // ✅ Ortak Uyarı Metodu
  void _showGuestWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bu özelliği kullanabilmek için kayıtlı kullanıcı olmalısınız."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF5D3FD3),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Ortak Buton Tasarımı
  Widget _buildGradientButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required List<Color> colors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildHelpTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)));
  }

  // --- Yardım Metni Alanı ---
  Widget _buildHelpContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HelpItem(
            q: "Günlük serim (streak) neden sıfırlandı?",
            a: "Serinizi korumak için her gün en az bir quiz bitirmelisiniz. 24 saat aktif olmazsanız seriniz sıfırlanır.",
          ),
          const Divider(),
          _HelpItem(
            q: "Premium avantajları nelerdir?",
            a: "Tamamen reklamsız deneyim, genel sıralama tablosu ve yeni eklenecek paketlere öncelikli erişim kazanırsınız.",
          ),
          const Divider(),
          _HelpItem(
            q: "Günlük hedefim neden sıfırlandı?",
            a: "Hedef barı her gün taze bir başlangıç için sıfırlanır. Toplam puanınız ve öğrendiğiniz kelimeler ise her zaman korunur.",
          ),
          const Divider(),
          _HelpItem(
            q: "Yanlış kelimeleri nasıl tekrar ederim?",
            a: "Ana ekrandaki 'Yanlışlarım' bölümüne giderek sadece hata yaptığınız kelimelerden oluşan özel quizler çözebilirsiniz.",
          ),
          const Divider(),
          _HelpItem(
            q: "XP (Puan) sistemi nasıl çalışıyor?",
            a: "Her doğru cevap size XP kazandırır. Seriniz arttıkça kazandığınız puan çarpanı da yükselir.",
          ),
          const Divider(),
          _HelpItem(
            q: "Misafir verileri silinir mi?",
            a: "Misafir verileri sadece cihazınızda tutulur. Verilerinizi buluta yedeklemek için hesap oluşturmanızı öneririz.",
          ),
          const Divider(),
          _HelpItem(
            q: "Verilerim güvende mi?",
            a: "Verileriniz Firebase ile korunur. Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak imha edilir.",
          ),
          const Divider(),
          _HelpItem(
            q: "Destek veya öneri için ne yapmalıyım?",
            a: "Geri bildirimleriniz için ayarlar sayfasındaki 'Bize Ulaşın' butonunu kullanabilir veya bize e-posta atabilirsiniz.",
          ),
        ],
      ),
    );
  }

  // --- Destek Talebi Alert Dialog ---
  void _showSupportDialog(BuildContext context) {
    final controller = TextEditingController();
    final viewModel = context.read<HelpViewModel>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF5D3FD3)),
            SizedBox(width: 10),
            Text("Destek Talebi", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Yaşadığınız sorunlar için öncelikle yardım sayfasındaki sıkça sorulan soruları incelemenizi öneririz. Eğer çözüm bulamadıysanız, mesajınızı aşağıya yazarak bize ulaşabilirsiniz.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 10,),
            const Text(
              "Talebinize 24 saat içerisinde yanıt verilecektir",
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Sorununuzu veya talebinizi buraya yazın...",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3FD3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (controller.text.isEmpty) return;
              bool res = await viewModel.sendHelpRequest(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res ? "Talebiniz başarıyla iletildi." : "Bir hata oluştu."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Gönder", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String q, a;
  const _HelpItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF5D3FD3))),
          const SizedBox(height: 5),
          Text(a, style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade700, height: 1.4)),
        ],
      ),
    );
  }
}