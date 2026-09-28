# butce

Kişisel finans defteri: aylık döviz birikimi, bütçe ve tekrar eden ödemeler.
Tek sayfalık bir uygulama — çerçeve yok, derleme adımı yok, dış bağımlılık yok.
Veriler Supabase'de (PostgreSQL) tutulur.

## Modüller

**Döviz Birikimi** — Her ay alınan dolar ve euro, ödenen TL, vergi dilimi.
Alış kurunu, vergi iadesini ve TCMB güncel kuruna göre bugünkü karşılığı
kendisi hesaplar. Aya ait dekont PDF'leri Supabase Storage'da saklanır,
tablodaki tutara tıklayınca imzalı bağlantıyla açılır.

**Aylık Bütçe** — Taksitler bir kez tanımlanır (ilk ve son ödeme ayı);
aradaki her aya kendiliğinden düşer, son ayda "son taksit" olarak işaretlenir,
sonrasında listeden çıkar. Aylık maaş, faturalar ve o aya özel giderler girilir;
kalan hesaplanır. "Önceki aydan kopyala" ile yeni ay tek tıkla açılır.

**Ödemeler** — Tekrar eden borç ve faturalar: nereye, ne kadar, ayın kaçında,
ne zaman bitecek. Ödeme günü gelenler kırmızı, gelmeyenler sarı, ödenenler
yeşil görünür. Tutar aya göre değişebilir (kart ekstresi gibi): bir ayın
tutarını değiştirmek o ay ve sonrasını etkiler, önceki aylar kendi tutarında kalır.

## Dosyalar

| Yol | Ne işe yarar |
|---|---|
| `index.html` | Uygulamanın tamamı (tüm modüller, mobil uyumlu arayüz, güvenlik katmanı). |
| `tcmb.xml` | TCMB günlük resmi XML kur verisi (CORS engeline takılmadan doğrudan depodan okunur). |
| `.github/workflows/update-tcmb.yml` | Her iş günü 15:35'te TCMB'den XML kurunu otomatik güncelleyen GitHub Action. |
| `_redirects` | Netlify üzerinde `/tcmb` isteğini TCMB günlük XML'ine yönlendirir. |
| `db/supabase-kurulum.sql` | Tablolar, RLS politikaları, Storage kovası. Bir kez çalıştırılır, tekrar çalıştırmak güvenlidir. |
| `yerel/Birikim-ve-Butce-Defteri.html` | Aynı uygulamanın çevrimdışı/yerel açılabilen kopyası. |

## TCMB Döviz Kurları

TCMB sunucuları (`https://www.tcmb.gov.tr/kurlar/today.xml`) tarayıcı içi doğrudan isteklerde CORS izin başlığı göndermediği için çok katmanlı, kesintisiz bir mimari kurulmuştur:

1. **Canlı TCMB XML İsteği:** Doğrudan TCMB XML'i çekilmeye çalışılır.
2. **Depo İçi Senkronize XML (`./tcmb.xml`):** GitHub Actions her iş günü TCMB bülten saati olan 15:35'te resmi XML dosyasını repoya günceller. GitHub Pages, Netlify veya yerel sunucularda CORS sorunu olmadan doğrudan okunur.
3. **Vekil Yönlendirme (`/tcmb`):** Netlify / sunucu proxy desteği.
4. **Yedek CORS Proxy & Döviz API:** Dış ağlar için alternatif kaynaklar.
5. **XML Yapıştır / Yükle Seçeneği:** Kurumsal katı güvenlik duvarları arkasında bile `today.xml` içeriğini yapıştırarak veya dosyayı seçerek tek tıkla kurları aktarabilme imkânı.

## Mobil Kullanım ve Okunabilirlik

Her 3 sekme de akıllı telefon ekranlarına göre optimize edilmiştir:

- **Döviz Birikimi:** Dar ekranda yatay kaydırma yapılırken **Dönem** sütunu sabit (yapışkan) kalarak hangi aya bakıldığı asla kaybolmaz.
- **Aylık Bütçe:** Taksit listesi dar ekranlarda bozulmayan, kart formatında okunaklı bir düzene kavuşmuştur. Ay değiştirme düğmeleri dokunmatik ekranlara uygun genişliktedir.
- **Ödemeler:** Ödenenler (yeşil), günü gelen/geçenler (kırmızı) ve bekleyenler (sarı/kehribar) yüksek kontrastlı sol renk çizgisi ve etiketleriyle ayrılmıştır. Ödemeler sekmesinde bekleyen/geciken ödeme adedi sayı rozeti olarak gösterilir.
- **Yapışkan Sekme Çubuğu:** Sayfa kaydırılsa dahi sekmeler ekranın üstünde sabit kalarak tek dokunuşla geçiş sağlar.

## Güvenlik

Dışarıdan gelebilecek müdahalelere karşı katmanlı güvenlik önlemleri alınmıştır:

- **Content-Security-Policy (CSP):** Sayfa düzeyinde sıkı CSP politikası tanımlanmıştır; izinsiz dış betiklerin çalışması ve XSS engellenir.
- **Kaba Kuvvet (Brute-Force) Koruması:** Giriş ekranında 5 ardışık hatalı parola denemesinde form otomatik olarak 60 saniye kilitlenir ve geri sayım başlar.
- **Dinamik E-Posta / Hesap Gizliliği:** Kullanıcı adı/e-posta kodu depoda sabit kalmak zorunda değildir; giriş ekranından değiştirilebilir ve tarayıcıda yerel saklanır.
- **Prototip Kirlenmesi (Prototype Pollution) Koruması:** Yedek yükleme (JSON import) işlemlerinde `__proto__`, `constructor` gibi anahtarlar temizlenir.
- **Satır Bazlı Güvenlik (RLS):** Supabase tablolarında RLS aktiftir; kimlik doğrulanmadan hiçbir kullanıcı verisi okunamaz veya yazılamaz.

## Kurulum

1. Supabase'de yeni proje aç.
2. SQL Editor'de `db/supabase-kurulum.sql` dosyasını çalıştır. Çıktıdaki sekiz
   satırın hepsinde `rls_acik = t` olmalı.
3. Authentication → Users → **Create new user**: e-posta ve parola belirle,
   "Auto Confirm User" işaretli olsun.
4. `index.html` içindeki `SUPABASE_AYAR` bloğunu doldur: proje adresi ve publishable anahtar.
5. Depoyu GitHub Pages, Netlify veya dilediğin statik barındırıcıya bağla.

## Veri taşıma

Uygulamanın altındaki **Yedek al** düğmesi tüm modülleri ve dekontları tek bir
JSON dosyasına indirir. **Yedeği yükle** aynı dosyayı geri alır ve veritabanına
yazar; dekontlar Storage'a yüklenir. Cihaz değiştirirken veya veritabanını
sıfırdan kurarken kullanılır.
