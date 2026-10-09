// scripts/guncelle-kurlar.js
// TCMB today.xml adresinden güncel kurları çekip kurlar.json dosyasını günceller.
const fs = require('fs');
const path = require('path');

const TCMB_URL = 'https://www.tcmb.gov.tr/kurlar/today.xml';

function parseTcmbXml(xml) {
  const mDate = xml.match(/Tarih_Date[^>]*Tarih="([^"]+)"/i);
  const tarih = mDate ? mDate[1] : '';

  function getCurrency(code) {
    const re = new RegExp('<Currency[^>]*Kod="' + code + '"[\\s\\S]*?<\\/Currency>', 'i');
    const m = xml.match(re);
    if (!m) return null;
    const chunk = m[0];

    const getVal = (tag) => {
      const match = chunk.match(new RegExp('<' + tag + '>([^<]+)<\\/' + tag + '>', 'i'));
      return match ? parseFloat(match[1].trim().replace(',', '.')) : 0;
    };

    const isim = (chunk.match(/<Isim>([^<]+)<\/Isim>/i) || ['', code])[1].trim();

    return {
      kod: code,
      isim: isim,
      efektifAlis: getVal('BanknoteBuying') || getVal('ForexBuying'),
      efektifSatis: getVal('BanknoteSelling') || getVal('ForexSelling'),
      dovizAlis: getVal('ForexBuying'),
      dovizSatis: getVal('ForexSelling')
    };
  }

  const usd = getCurrency('USD');
  const eur = getCurrency('EUR');

  return {
    tarih: tarih,
    guncellenme: new Date().toISOString(),
    usd: usd,
    eur: eur
  };
}

async function main() {
  console.log('TCMB kurları çekiliyor:', TCMB_URL);
  try {
    const res = await fetch(TCMB_URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });

    if (!res.ok) {
      throw new Error(`HTTP ${res.status} ${res.statusText}`);
    }

    const xml = await res.text();
    if (!xml.includes('Tarih_Date')) {
      throw new Error('Geçersiz XML içeriği');
    }

    const data = parseTcmbXml(xml);
    const targetFile = path.join(__dirname, '..', 'kurlar.json');
    fs.writeFileSync(targetFile, JSON.stringify(data, null, 2), 'utf8');

    console.log(`[BAŞARILI] kurlar.json güncellendi!`);
    console.log(`- Tarih: ${data.tarih}`);
    console.log(`- USD Efektif Alış: ${data.usd ? data.usd.efektifAlis : 'yok'}`);
    console.log(`- EUR Efektif Alış: ${data.eur ? data.eur.efektifAlis : 'yok'}`);
  } catch (err) {
    console.error('[HATA] TCMB kurları çekilemedi:', err.message);
    process.exit(1);
  }
}

main();
