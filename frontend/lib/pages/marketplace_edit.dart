import 'package:flutter/material.dart';
// keep for uploads in other contexts; not used here
import '../l10n/app_localizations.dart';
import '../widgets/status_banner.dart';
import '../app/locator.dart';
import '../features/marketplace/domain/usecases/get_ad.dart';
import '../features/marketplace/domain/usecases/update_ad.dart';

class MarketplaceEditPage extends StatefulWidget {
  final String token;
  final String adId;
  const MarketplaceEditPage({super.key, required this.token, required this.adId});
  @override
  State<MarketplaceEditPage> createState() => _MarketplaceEditPageState();
}

class _MarketplaceEditPageState extends State<MarketplaceEditPage> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String type = 'venda';
  String feedback = '';
  bool loading = true;

  Future<void> load() async {
    final r = await GetAdUseCase(Locator.marketplace)(widget.adId);
    if (r.isOk && r.data != null) {
      final a = r.data!;
      titleCtrl.text = a.title;
      descCtrl.text = a.description;
      priceCtrl.text = a.price;
      type = a.type;
    }
    loading = false;
    setState(() {});
  }

  Future<void> save() async {
    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    final price = double.tryParse(priceCtrl.text);
    final t = type;
    final r = await UpdateAdUseCase(Locator.marketplace)(widget.adId, title: title, description: description, price: price, type: t);
    if (r.isOk) {
      feedback = 'Atualizado';
      setState(() {});
      Navigator.of(context).pop(true);
    } else {
      feedback = 'Falha ao atualizar';
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
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.edit)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: type,
                    items: [
                      DropdownMenuItem(value: 'venda', child: Text(t.sale)),
                      DropdownMenuItem(value: 'compra', child: Text(t.buy)),
                      DropdownMenuItem(value: 'troca', child: Text(t.trade)),
                    ],
                    onChanged: (v) => setState(() => type = v ?? 'venda'),
                  ),
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: t.title)),
                  TextField(controller: descCtrl, decoration: InputDecoration(labelText: t.description)),
                  TextField(controller: priceCtrl, decoration: InputDecoration(labelText: t.price), keyboardType: TextInputType.number),
                  const Spacer(),
                  ElevatedButton(onPressed: save, child: Text(t.save)),
                  const SizedBox(height: 8),
                  if (feedback.isNotEmpty) StatusBanner(text: feedback, type: feedback.startsWith('Falha') ? 'error' : 'success'),
                ],
              ),
            ),
    );
  }
}
