import 'package:flutter/material.dart';
import 'package:poketibia_platform_frontend/widgets/background_carousel_widget.dart';
import 'package:poketibia_platform_frontend/widgets/welcome_image_carousel_widget.dart';
import 'register.dart';
import 'forgot.dart';
import '../widgets/status_banner.dart';
import '../l10n/app_localizations.dart';
import '../app.dart';
import '../app/locator.dart';
import '../features/auth/domain/usecases/login.dart';
import '../widgets/guest_app_bar.dart';

class LoginPage extends StatefulWidget {
  final void Function(String accessToken, String? refreshToken) onLoggedIn;
  const LoginPage({super.key, required this.onLoggedIn});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String? error;
  bool loggingIn = false;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  final String bgAsset = 'assets/login_bg.png';
  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    
    if (email.isEmpty || pass.isEmpty) {
      final t = AppLocalizations.of(context);
      setState(() => error = t.provideEmailPassword);
      return;
    }
    loggingIn = true;
    setState(() => error = null);
    final r = await LoginUseCase(Locator.auth)(email, pass);
    if (r.isOk && r.data != null) {
      widget.onLoggedIn(r.data!.accessToken, r.data!.refreshToken);
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppRoot()));
    } else {
      final t = AppLocalizations.of(context);
      error = t.loginFailed;
      setState(() {});
    }
    loggingIn = false;
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: GuestAppBar(selectedSection: "login",),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackgroundCarousel(),
          // Container(
          //   decoration: BoxDecoration(
          //     image: DecorationImage(image: AssetImage(bgAsset), fit: BoxFit.cover),
          //   ),
          //   child: Container(
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         colors: [brandBlack.withValues(alpha: 0.7), brandBlack.withValues(alpha: 0.3)],
          //         begin: Alignment.bottomCenter,
          //         end: Alignment.topCenter,
          //       ),
          //     ),
          //   ),
          // ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.catching_pokemon, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Bem-vindo ao PokeGenTrade', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const WelcomeImageCarousel(),
                      // ClipRRect(
                      //   borderRadius: BorderRadius.circular(12),
                      //   child: Image.asset(
                      //     bgAsset,
                      //     height: 120,
                      //     width: double.infinity,
                      //     fit: BoxFit.cover,
                      //   ),
                      // ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: t.email,
                          prefixIcon: Icon(Icons.person, color: brandRed),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPage()));
                          },
                          child: Text(t.forgotPassword, style: TextStyle(color: brandBlack)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: loggingIn ? null : login,
                          child: Text(loggingIn ? t.entering : t.enter),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RegisterPage(onRegistered: widget.onLoggedIn),
                          ));
                        },
                        child: Text(t.createAccount, style: TextStyle(color: brandRed)),
                      ),
                      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: StatusBanner(text: error!, type: 'error')),
                      const SizedBox(height: 8),
                      Text(t.disclaimer, style: TextStyle(color: brandBlack.withValues(alpha: 0.8))),
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
