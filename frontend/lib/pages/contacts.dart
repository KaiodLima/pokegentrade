import 'package:flutter/material.dart';
import 'dm.dart';
import '../widgets/status_banner.dart';
import '../app/locator.dart';
import '../features/users/domain/usecases/get_online_users.dart';

class ContactsPage extends StatefulWidget {
  final String token;
  const ContactsPage({super.key, required this.token});
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>> users = [];
  String feedback = '';
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  Future<void> load() async {
    final r = await GetOnlineUsersUseCase(Locator.users)();
    if (r.isOk) {
      users = (r.data ?? []).map<Map<String, dynamic>>((e) => {'id': e.id, 'name': e.displayName}).toList();
      feedback = '';
      setState(() {});
    } else {
      feedback = 'Erro ao carregar';
      setState(() {});
    }
  }
  @override
  void initState() {
    super.initState();
    load();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contatos Online'), actions: [
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      ]),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/login_bg.png'), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brandBlack.withValues(alpha: 0.7), brandBlack.withValues(alpha: 0.3)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.people, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Contatos Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: StatusBanner(text: feedback, type: 'error', actionText: 'Tentar novamente', onAction: load)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (_, i) {
                            final u = users[i];
                            return ListTile(
                              title: Text((u['name'] ?? '').toString().isNotEmpty ? u['name'] : u['id']),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => DmPage(token: widget.token, userId: u['id'])));
                                },
                                child: const Text('DM'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
