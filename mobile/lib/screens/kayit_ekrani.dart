import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';

import '../core/dogrulayicilar.dart';
import '../providers/auth_provider.dart';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});

  @override
  State<KayitEkrani> createState() => _KayitEkraniDurumu();
}

class _KayitEkraniDurumu extends State<KayitEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _adSoyadDenetleyici = TextEditingController();
  final _epostaDenetleyici = TextEditingController();
  final _parolaDenetleyici = TextEditingController();
  final _parolaTekrarDenetleyici = TextEditingController();

  bool _parolaGizli = true;

  @override
  void dispose() {
    _adSoyadDenetleyici.dispose();
    _epostaDenetleyici.dispose();
    _parolaDenetleyici.dispose();
    _parolaTekrarDenetleyici.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final saglayici = context.read<AuthProvider>();
    final yonlendirici = Navigator.of(context);

    final basarili = await saglayici.kayitOl(
      eposta: _epostaDenetleyici.text.trim(),
      parola: _parolaDenetleyici.text,
      adSoyad: _adSoyadDenetleyici.text.trim(),
    );

    if (!mounted) return;

    if (basarili) {
      // Kayıt başarılı: sunucu token de döndürdüğü için kullanıcı zaten
      // giriş yapmış sayılır. Altta giriş ekranı da durabileceğinden tek
      // `pop` yetmez; yığın kökene kadar temizlenip kullanıcı gezindiği
      // sekmeye bırakılıyor.
      yonlendirici.popUntil((rota) => rota.isFirst);
      return;
    }

    Bildirim(context).hata(saglayici.hata ?? 'Kayıt yapılamadı.');
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = context.watch<AuthProvider>().islemSuruyor;

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formAnahtari,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                Text(
                  'Hesap oluşturun',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _adSoyadDenetleyici,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: Dogrulayicilar.adSoyad,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _epostaDenetleyici,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: Dogrulayicilar.eposta,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _parolaDenetleyici,
                  obscureText: _parolaGizli,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Parola',
                    helperText: 'En az 8 karakter',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _parolaGizli
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _parolaGizli = !_parolaGizli),
                    ),
                  ),
                  validator: Dogrulayicilar.parola,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _parolaTekrarDenetleyici,
                  obscureText: _parolaGizli,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _gonder(),
                  decoration: const InputDecoration(
                    labelText: 'Parola (Tekrar)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (deger) => Dogrulayicilar.parolaTekrari(
                    deger,
                    _parolaDenetleyici.text,
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: islemSuruyor ? null : _gonder,
                  child: islemSuruyor
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kayıt Ol'),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed:
                      islemSuruyor ? null : () => Navigator.of(context).pop(),
                  child: const Text('Zaten hesabım var'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
