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
| `index.html` | Uygulamanın tamamı. Netlify kökü. |
| `_redirects` | `/tcmb` isteğini TCMB'nin günlük kur XML'ine yönlendirir (CORS'u aşmak için sunucu tarafı vekil). |
| `db/supabase-kurulum.sql` | Tablolar, RLS politikaları, Storage kovası. Bir kez çalıştırılır, tekrar çalıştırmak güvenlidir. |
| `yerel/Birikim-ve-Butce-Defteri.html` | Aynı uygulamanın çevrimdışı açılabilen kopyası. |

## Kurulum

1. Supabase'de yeni proje aç.
2. SQL Editor'de `db/supabase-kurulum.sql` dosyasını çalıştır. Çıktıdaki sekiz
   satırın hepsinde `rls_acik = t` olmalı.
3. Authentication → Users → **Create new user**: e-posta ve parola belirle,
   "Auto Confirm User" işaretli olsun.
4. `index.html` içindeki `SUPABASE_AYAR` bloğunu doldur: proje adresi,
   **publishable** anahtar ve giriş e-postası.
5. Depoyu Netlify'a bağla (build komutu yok, yayın klasörü depo kökü).

## Güvenlik

Sayfadaki anahtar **publishable** anahtardır; herkese açık olacak şekilde
tasarlanmıştır. Asıl koruma veritabanındaki RLS politikalarıdır: her satır
`user_id = auth.uid()` koşuluna bağlıdır, giriş yapılmadan tek satır okunamaz
ve kimse başkasının satırını yazamaz.

- **Gizli (`secret` / `service_role`) anahtarı bu depoya veya sayfaya koyma.**
  O anahtar RLS'i tamamen es geçer.
- Kişisel veri içeren yedek dosyaları (`veri*.json`, `doviz-defteri-*.json`)
  `.gitignore` ile dışarıda bırakılmıştır. Depoya eklemeyin.
- Depoyu **private** tutmak, e-postanın ve proje adresinin indekslenmemesi
  açısından tercih edilir.

## Veri taşıma

Uygulamanın altındaki **Yedek al** düğmesi tüm modülleri ve dekontları tek bir
JSON dosyasına indirir. **Yedeği yükle** aynı dosyayı geri alır ve veritabanına
yazar; dekontlar Storage'a yüklenir. Cihaz değiştirirken veya veritabanını
sıfırdan kurarken kullanılır.
