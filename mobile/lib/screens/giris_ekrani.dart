import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';

import '../core/dogrulayicilar.dart';
import '../providers/auth_provider.dart';
import 'kayit_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniDurumu();
}

/// Form alanları kullanıcı yazdıkça değiştiği için ekran `StatefulWidget`.
/// Denetleyicilerin (`TextEditingController`) yaşam süresi widget'a bağlı.
class _GirisEkraniDurumu extends State<GirisEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _epostaDenetleyici = TextEditingController();
  final _parolaDenetleyici = TextEditingController();

  bool _parolaGizli = true;

  @override
  void dispose() {
    // Denetleyiciler bellekte yer tutar; ekran kapanınca serbest bırakılır.
    _epostaDenetleyici.dispose();
    _parolaDenetleyici.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    // Önce istemci tarafı doğrulama. Geçersizse sunucuya hiç gidilmez.
    if (!_formAnahtari.currentState!.validate()) return;

    final saglayici = context.read<AuthProvider>();

    final basarili = await saglayici.girisYap(
      eposta: _epostaDenetleyici.text.trim(),
      parola: _parolaDenetleyici.text,
    );

    // Asenkron çağrı sırasında ekran kapanmış olabilir.
    if (!mounted) return;

    if (!basarili) {
      Bildirim(context).hata(saglayici.hata ?? 'Giriş yapılamadı.');
    }

    // Başarılıysa yönlendirme yapılmaz: oturum durumu değişince
    // `main.dart` içindeki sarmalayıcı ana ekranı kendisi açar.
  }

  @override
  Widget build(BuildContext context) {
    // `watch` ile dinleniyor: işlem sürerken buton kilitlensin diye
    // durum değiştiğinde bu widget yeniden çizilmeli.
    final islemSuruyor = context.watch<AuthProvider>().islemSuruyor;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formAnahtari,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  Icon(
                    Icons.storefront,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'İSKİ E-Ticaret',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Devam etmek için giriş yapın',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _gonder(),
                    decoration: InputDecoration(
                      labelText: 'Parola',
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
                  const SizedBox(height: 24),

                  FilledButton(
                    // Buton işlem sürerken kilitlenir: kullanıcı iki kez
                    // basarsa iki istek gitmesin.
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
                        : const Text('Giriş Yap'),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: islemSuruyor
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const KayitEkrani(),
                              ),
                            ),
                    child: const Text('Hesabınız yok mu? Kayıt olun'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
