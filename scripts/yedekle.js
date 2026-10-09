// scripts/yedekle.js
// Supabase veritabanındaki verileri çekip Bütçe Defteri formatında JSON yedek dosyası oluşturur.

const fs = require('fs');
const path = require('path');

// URL Düzeltme: Kullanıcı Supabase panel adresini (dashboard) yapıştırmışsa otomatik API adresine çevir
let rawUrl = (process.env.SUPABASE_URL || 'https://vvsoyooedstcrsohqnfj.supabase.co').trim().replace(/\/+$/, '');
if (rawUrl.includes('supabase.com') || !rawUrl.includes('.supabase.co')) {
  const match = rawUrl.match(/project\/([a-z0-9]+)/i);
  if (match) {
    rawUrl = `https://${match[1]}.supabase.co`;
  } else {
    rawUrl = 'https://vvsoyooedstcrsohqnfj.supabase.co';
  }
}
const URL = rawUrl;

const DEFAULT_KEY = 'sb_publishable_xV8OnKCk-OYwDVDV6et6fw_669TJ9KQ';
const ENV_KEY = (process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || '').trim();

async function get(tablo) {
  const url = `${URL}/rest/v1/${tablo}?select=*`;
  const keysToTry = ENV_KEY ? [ENV_KEY, DEFAULT_KEY] : [DEFAULT_KEY];

  for (const k of keysToTry) {
    try {
      const res = await fetch(url, {
        method: 'GET',
        headers: {
          'apikey': k,
          'Authorization': `Bearer ${k}`,
          'Content-Type': 'application/json'
        }
      });

      const text = await res.text();
      if (res.ok && !text.trim().startsWith('<')) {
        const data = JSON.parse(text);
        const rows = Array.isArray(data) ? data : [];
        console.log(`- ${tablo}: ${rows.length} satır okundu (HTTP ${res.status})`);
        return rows;
      } else {
        console.warn(`[UYARI] ${tablo} okunamadı (HTTP ${res.status}): ${text.slice(0, 80)}`);
      }
    } catch (e) {
      console.warn(`[UYARI] ${tablo} hatası:`, e.message);
    }
  }
  return [];
}

async function calistir() {
  console.log(`Hedef Supabase API: ${URL}`);

  console.log('Tablolar okunuyor:');
  const [ayarRows, dvRows, tkRows, baRows, bkRows, odRows, oddRows, odtRows] = await Promise.all([
    get('ayarlar'),
    get('doviz_aylar'),
    get('taksitler'),
    get('butce_aylar'),
    get('butce_kalemler'),
    get('odemeler'),
    get('odeme_durum'),
    get('odeme_tutar')
  ]);

  const a = (ayarRows && ayarRows[0]) || {};
  const dv = (dvRows || []).sort((x, y) => ((x.yil || 0) * 12 + (x.ay || 0)) - ((y.yil || 0) * 12 + (y.ay || 0)));
  const tk = (tkRows || []).sort((x, y) => {
    if (x.sira !== undefined && y.sira !== undefined && x.sira !== y.sira) return (x.sira || 0) - (y.sira || 0);
    return ((x.bas_yil || 0) * 12 + (x.bas_ay || 0)) - ((y.bas_yil || 0) * 12 + (y.bas_ay || 0));
  });
  const ba = (baRows || []).sort((x, y) => ((x.yil || 0) * 12 + (x.ay || 0)) - ((y.yil || 0) * 12 + (y.ay || 0)));
  const bk = (bkRows || []).sort((x, y) => (x.sira || 0) - (y.sira || 0));
  const od = (odRows || []).sort((x, y) => {
    if (x.sira !== undefined && y.sira !== undefined && x.sira !== y.sira) return (x.sira || 0) - (y.sira || 0);
    return (x.gun || 0) - (y.gun || 0);
  });
  const odd = oddRows || [];
  const odt = odtRows || [];

  console.log(`\nToplam Veri Özeti:`);
  console.log(`Döviz: ${dv.length}, Taksit: ${tk.length}, Bütçe Ay: ${ba.length}, Kalem: ${bk.length}, Ödeme: ${od.length}`);

  const toplamSatir = dv.length + tk.length + ba.length + bk.length + od.length;
  if (toplamSatir === 0) {
    throw new Error('Veritabanında hiç satır bulunamadı veya adres hatalı!');
  }

  const state = {
    savedAt: Date.now(),
    usdRate: Number(a.usd_kur || 0),
    eurRate: Number(a.eur_kur || 0),
    rateDate: String(a.kur_tarihi || ''),
    rows: dv.map(x => ({
      id: x.id,
      year: x.yil,
      month: x.ay,
      usd: Number(x.usd || 0),
      usdTl: Number(x.usd_tl || 0),
      eur: Number(x.eur || 0),
      eurTl: Number(x.eur_tl || 0),
      extra: Number(x.ek_tl || 0),
      tax: Number(x.vergi_dilimi || 0),
      usdDoc: x.usd_dekont || null,
      eurDoc: x.eur_dekont || null
    })),
    butce: {
      taksitler: tk.map(x => ({
        id: x.id,
        ad: x.ad || '',
        tutar: Number(x.tutar || 0),
        bYil: x.bas_yil,
        bAy: x.bas_ay,
        sYil: x.bit_yil,
        sAy: x.bit_ay
      })),
      aylar: ba.map(x => {
        const f = [], g = [];
        bk.filter(k => k.ay_id === x.id).forEach(k => {
          (k.tur === 'fatura' ? f : g).push({
            id: k.id,
            ad: k.ad || '',
            tutar: Number(k.tutar || 0),
            sira: Number(k.sira || 0)
          });
        });
        f.sort((p, q) => (p.sira || 0) - (q.sira || 0));
        g.sort((p, q) => (p.sira || 0) - (q.sira || 0));
        return {
          id: x.id,
          yil: x.yil,
          ay: x.ay,
          maas: Number(x.maas || 0),
          hesaba: Number(x.hesaba || 0),
          gonderimler: Array.isArray(x.gonderimler) ? x.gonderimler : (Number(x.hesaba || 0) > 0 ? [{ ad: "Hesaba Gönderim", tutar: Number(x.hesaba) }] : []),
          faturalar: f,
          giderler: g
        };
      })
    },
    odemeler: od.map(x => {
      const d = {}, t = {};
      odd.filter(k => k.odeme_id === x.id).forEach(k => {
        d[`${k.yil}-${k.ay}`] = !!k.odendi;
      });
      odt.filter(k => k.odeme_id === x.id).forEach(k => {
        t[`${k.yil}-${k.ay}`] = Number(k.tutar || 0);
      });
      return {
        id: x.id,
        ad: x.ad || '',
        tutar: Number(x.tutar || 0),
        gun: x.gun || 1,
        bYil: x.bas_yil,
        bAy: x.bas_ay,
        bitYil: x.bit_yil || 0,
        bitAy: x.bit_ay || 0,
        odenen: d,
        tutarlar: t
      };
    })
  };

  const paket = {
    format: 'doviz-defteri',
    v: 1,
    alindi: new Date().toISOString(),
    state: state,
    docs: {}
  };

  const bugun = new Date().toISOString().slice(0, 10);
  const ciktiDosyasi = path.resolve(process.cwd(), `butce-yedek-${bugun}.json`);
  fs.writeFileSync(ciktiDosyasi, JSON.stringify(paket, null, 2), 'utf8');

  console.log(`✅ Yedek başarıyla kaydedildi: ${ciktiDosyasi} (${fs.statSync(ciktiDosyasi).size} bayt)`);
}

calistir().catch(err => {
  console.error('Kritik hata:', err.message || err);
  process.exit(1);
});
