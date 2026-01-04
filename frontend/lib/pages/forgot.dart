import 'package:flutter/material.dart';
// Mantido para compatibilidade com componentes que usam Api diretamente
import '../widgets/status_banner.dart';
import '../l10n/app_localizations.dart';
import '../app/locator.dart';
import '../features/auth/domain/usecases/forgot.dart';
import '../features/auth/domain/usecases/reset.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});
  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final emailCtrl = TextEditingController();
  bool loading = false;
  String? token;
  String? error;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  Future<void> submit() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => error = 'Informe o email');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      token = null;
    });
    final r = await ForgotUseCase(Locator.auth)(email);
    if (r.isOk && r.data != null && r.data!.isNotEmpty) {
      token = r.data!;
    } else {
      error = 'Falha ao emitir token';
    }
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.forgotPassword)),
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
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 250),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.lock_reset, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Recuperação de senha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: emailCtrl, decoration: InputDecoration(labelText: t.email, prefixIcon: Icon(Icons.email, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white), onPressed: loading ? null : submit, child: Text(loading ? t.entering : 'Gerar token')),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        StatusBanner(text: error!, type: 'error'),
                      ],
                      if (token != null) ...[
                        const SizedBox(height: 16),
                        SelectableText('Token: $token'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResetPage(prefilledToken: token!)));
                            },
                            child: const Text('Usar token para redefinir'),
                          ),
                        ),
                      ],
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

class ResetPage extends StatefulWidget {
  final String? prefilledToken;
  const ResetPage({super.key, this.prefilledToken});
  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final tokenCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;
  String? message;
  String? error;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  @override
  void initState() {
    super.initState();
    if (widget.prefilledToken != null) {
      tokenCtrl.text = widget.prefilledToken!;
    }
  }
  Future<void> submit() async {
    final token = tokenCtrl.text.trim();
    final pass = passCtrl.text;
    final conf = confirmCtrl.text;
    if (token.isEmpty || pass.isEmpty) {
      setState(() => error = 'Informe token e nova senha');
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
      message = null;
    });
    final r = await ResetUseCase(Locator.auth)(token: token, newPassword: pass);
    if (r.isOk) {
      message = 'Senha redefinida';
      setState(() {});
      Navigator.of(context).pop();
      return;
    } else {
      error = 'Falha ao redefinir';
    }
    loading = false;
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.password, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Redefinir senha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: tokenCtrl, decoration: const InputDecoration(labelText: 'Token')),
                      const SizedBox(height: 8),
                      TextField(controller: passCtrl, decoration: InputDecoration(labelText: t.password), obscureText: true),
                      const SizedBox(height: 8),
                      TextField(controller: confirmCtrl, decoration: const InputDecoration(labelText: 'Confirmar nova senha'), obscureText: true),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white), onPressed: loading ? null : submit, child: Text(loading ? t.entering : 'Redefinir'))),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      ],
                      if (message != null) ...[
                        const SizedBox(height: 8),
                        StatusBanner(text: message!, type: 'success'),
                      ],
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
