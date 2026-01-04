import 'package:flutter/material.dart';
import '../widgets/status_banner.dart';
import '../l10n/app_localizations.dart';
import '../app/locator.dart';
import '../features/auth/domain/usecases/register.dart';
import '../widgets/guest_app_bar.dart';

class RegisterPage extends StatefulWidget {
  final void Function(String accessToken, String? refreshToken) onRegistered;
  const RegisterPage({super.key, required this.onRegistered});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;
  String? error;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;

  Future<void> register() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    final conf = confirmCtrl.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => error = 'Preencha todos os campos');
      return;
    }
    if (pass.length < 6) {
      setState(() => error = 'A senha deve ter ao menos 6 caracteres');
      return;
    }
    if (pass != conf) {
      setState(() => error = 'As senhas não coincidem');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    final r = await RegisterUseCase(Locator.auth)(displayName: name, email: email, password: pass);
    if (r.isOk && r.data != null) {
      widget.onRegistered(r.data!.accessToken, r.data!.refreshToken);
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => error = 'Falha no registro');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: GuestAppBar(selectedSection: "register",),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: const DecorationImage(image: AssetImage('assets/login_bg.png'), fit: BoxFit.cover),
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
              constraints: const BoxConstraints(maxWidth: 880),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: SizedBox(
                  height: 480,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  image: const DecorationImage(image: AssetImage('assets/login_bg.png'), fit: BoxFit.cover),
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: brandBlack.withValues(alpha: 0.7),
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Já possui uma conta?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                                  const SizedBox(height: 8),
                                  Text('Acesse sua conta agora', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                                  const SizedBox(height: 20),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text(t.enter.toUpperCase()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, color: Colors.grey.shade200),
                      Expanded(
                        flex: 6,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(topRight: Radius.circular(18), bottomRight: Radius.circular(18)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cria sua conta', style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 20)),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Nome exibido',
                                    prefixIcon: Icon(Icons.person_add_alt_1, color: brandRed),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: emailCtrl,
                                  decoration: InputDecoration(
                                    labelText: t.email,
                                    prefixIcon: Icon(Icons.mail, color: brandRed),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: passCtrl,
                                  decoration: InputDecoration(
                                    labelText: t.password,
                                    prefixIcon: Icon(Icons.lock, color: brandRed),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: confirmCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar senha',
                                    prefixIcon: Icon(Icons.lock_outline, color: brandRed),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: loading ? null : register,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: brandRed,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(child: Text(loading ? t.entering : 'Cadastrar'.toUpperCase(), style: TextStyle(color: Colors.white),)),
                                    ),
                                  ),
                                ),
                                if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: StatusBanner(text: error!, type: 'error')),
                              ],
                            ),
                          ),
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
