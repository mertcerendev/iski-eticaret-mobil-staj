import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';

import '../core/dogrulayicilar.dart';
import '../providers/auth_provider.dart';
import 'kayit_ekrani.dart';

/// Giriş ekranını yığının üstüne açar.
///
/// Giriş artık uygulamanın kökü değil, gerektiğinde açılan bir ekran.
/// Nereden çağrıldığını bilmek zorunda kalmasın diye bu iş tek bir
/// yardımcıda toplandı.
void girisEkraniniAc(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const GirisEkrani()),
  );
}

/// Hesap gerektiren işlemlerin önündeki kapı.
///
/// Sepet, favori ve sipariş uçları sunucuda `auth` katmanının arkasında.
/// İstek atılıp 401 alınsaydı istemcideki interceptor bunu "oturum düştü"
/// sayıp token'ı silerdi — hiç oturum açmamış biri için anlamsız bir yol.
/// Bu yüzden istek atılmadan önce burada duruluyor.
///
/// Girişliyse `true` döner ve çağıran işine devam eder. Değilse kullanıcıya
/// sorulur, `false` döner ve işlem iptal edilir.
Future<bool> oturumGerekli(BuildContext context, String mesaj) async {
  if (context.read<AuthProvider>().girisYapildi) return true;

  final gidilsin = await showDialog<bool>(
    context: context,
    builder: (pencere) => AlertDialog(
      title: const Text('Giriş gerekli'),
      content: Text(mesaj),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(pencere).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(pencere).pop(true),
          child: const Text('Giriş Yap'),
        ),
      ],
    ),
  );

  if (gidilsin == true && context.mounted) girisEkraniniAc(context);

  return false;
}

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
    final yonlendirici = Navigator.of(context);

    final basarili = await saglayici.girisYap(
      eposta: _epostaDenetleyici.text.trim(),
      parola: _parolaDenetleyici.text,
    );

    // Asenkron çağrı sırasında ekran kapanmış olabilir.
    if (!mounted) return;

    if (!basarili) {
      Bildirim(context).hata(saglayici.hata ?? 'Giriş yapılamadı.');
      return;
    }

    // Bu ekrana kayıt ekranından da gelinmiş olabilir. `pop` yerine
    // `popUntil` kullanılıyor: yığında ne varsa temizlenip kullanıcı
    // gezindiği sekmeye geri bırakılıyor.
    yonlendirici.popUntil((rota) => rota.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // `watch` ile dinleniyor: işlem sürerken buton kilitlensin diye
    // durum değiştiğinde bu widget yeniden çizilmeli.
    final islemSuruyor = context.watch<AuthProvider>().islemSuruyor;

    return Scaffold(
      // Başlık çubuğu Gün 21'de eklendi: ekran artık uygulamanın kökü
      // değil, üstüne açılan bir sayfa. Geri oku olmasa misafir kullanıcı
      // vazgeçtiğinde ürünlere dönemezdi.
      appBar: AppBar(title: const Text('Giriş Yap')),
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

                  // Logonun içinde marka adı da var; ayrıca yazıyla
                  // tekrarlanmıyor.
                  Image.asset('assets/marka/logo.png', width: 220),
                  const SizedBox(height: 8),

                  Text(
                    'Sepet ve favoriler için hesabınıza girin',
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
