import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_bus.dart';
import '../services/notify.dart';

class SettingsPage extends StatefulWidget {
  final bool embedded;
  const SettingsPage({super.key, this.embedded = false});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool highContrast = false;
  double textScale = 1.0;
  String lang = 'pt';
  bool notifications = false;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highContrast = prefs.getBool('high_contrast') ?? false;
      textScale = prefs.getDouble('text_scale') ?? 1.0;
      lang = prefs.getString('lang') ?? 'pt';
      notifications = prefs.getBool('notifications_enabled') ?? false;
    });
  }
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', highContrast);
    await prefs.setDouble('text_scale', textScale);
    await prefs.setString('lang', lang);
    await Notify.setEnabled(notifications);
    SettingsBus.emit();
    Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) {
    final inner = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white.withValues(alpha: 0.95),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    children: const [
                      Icon(Icons.settings, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Configurações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Alto contraste'),
                  value: highContrast,
                  onChanged: (v) => setState(() => highContrast = v),
                ),
                SwitchListTile(
                  title: const Text('Notificações'),
                  value: notifications,
                  onChanged: (v) async {
                    setState(() => notifications = v);
                    await Notify.setEnabled(v);
                  },
                ),
                const SizedBox(height: 8),
                Text('Tamanho do texto (${textScale.toStringAsFixed(2)}x)'),
                Slider(
                  min: 0.9,
                  max: 1.5,
                  divisions: 12,
                  value: textScale,
                  label: '${(textScale * 100).round()}%',
                  onChanged: (v) => setState(() => textScale = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: lang,
                  items: const [
                    DropdownMenuItem(value: 'pt', child: Text('Português')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  decoration: InputDecoration(prefixIcon: Icon(Icons.language, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  onChanged: (v) => setState(() => lang = v ?? 'pt'),
                ),
                const Spacer(),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white), onPressed: _save, child: const Text('Salvar'))),
              ],
            ),
          ),
        ),
      ),
    );
    if (widget.embedded) {
      return inner;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/login_bg.png'), fit: BoxFit.cover)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [brandBlack.withValues(alpha: 0.7), brandBlack.withValues(alpha: 0.3)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            ),
          ),
        ),
        inner,
      ]),
    );
  }
}
