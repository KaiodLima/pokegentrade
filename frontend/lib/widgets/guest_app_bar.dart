import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../pages/login.dart';
import '../pages/register.dart';
import '../pages/home.dart';
import '../pages/marketplace_list.dart';
import '../services/api.dart';
import '../app.dart';

class GuestAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? selectedSection;
  const GuestAppBar({super.key, this.title, required this.selectedSection});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.catching_pokemon, color: Colors.white),
          const SizedBox(width: 8),
          Text('PokeGenTrade', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if(selectedSection != "welcome"){
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
            }
          },
          child: Text(t.home, style: const TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            if(selectedSection != "maketplace"){
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MarketplaceListPage(token: '', embedded: false)));
            }
          },
          child: Text(t.marketplace, style: const TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            if(selectedSection != "login"){
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage(onLoggedIn: (a, r) async {
                await Api.setTokens(a, r);
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppRoot()));
              })));
            }
          },
          child: Text(t.enter, style: const TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            if(selectedSection != "register"){
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterPage(onRegistered: (a, r) async {
                await Api.setTokens(a, r);
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppRoot()));
              })));
            }
          },
          child: Text("Criar Conta", style: const TextStyle(color: Colors.white)),
        ),
        
        
      ],
    );
  }
}
