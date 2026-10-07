// scripts/yedekle.js
// Supabase veritabanındaki verileri çekip Bütçe Defteri formatında JSON yedek dosyası oluşturur.

const fs = require('fs');
const path = require('path');

const URL = (process.env.SUPABASE_URL || 'https://vvsoyooedstcrsohqnfj.supabase.co').replace(/\/+$/, '');
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY;

if (!KEY) {
  console.error('HATA: SUPABASE_SERVICE_ROLE_KEY veya SUPABASE_KEY ortam değişkeni tanımlanmamış!');
  process.exit(1);
}

async function get(tablo, query = '') {
  const url = `${URL}/rest/v1/${tablo}?select=*${query ? '&' + query : ''}`;
  const res = await fetch(url, {
    method: 'GET',
    headers: {
      'apikey': KEY,
      'Authorization': `Bearer ${KEY}`,
      'Content-Type': 'application/json'
    }
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Tablo [${tablo}] okunamadı (HTTP ${res.status}): ${errText}`);
  }
  return res.json();
}

async function calistir() {
  console.log(`Supabase bağlantısı kuruluyor: ${URL}`);

  const [ayarRows, dvRows, tkRows, baRows, bkRows, odRows, oddRows, odtRows] = await Promise.all([
    get('ayarlar'),
    get('doviz_aylar', 'order=yil.asc,ay.asc'),
    get('taksitler', 'order=bas_yil.asc,bas_ay.asc'),
    get('butce_aylar', 'order=yil.asc,ay.asc'),
    get('butce_kalemler', 'order=sira.asc'),
    get('odemeler', 'order=gun.asc'),
    get('odeme_durum'),
    get('odeme_tutar')
  ]);

  const a = (ayarRows && ayarRows[0]) || {};
  const dv = dvRows || [];
  const tk = tkRows || [];
  const ba = baRows || [];
  const bk = bkRows || [];
  const od = odRows || [];
  const odd = oddRows || [];
  const odt = odtRows || [];

  console.log(`Veriler alındı: ${dv.length} döviz ayı, ${tk.length} taksit, ${ba.length} bütçe ayı, ${od.length} ödeme.`);

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
            tutar: Number(k.tutar || 0)
          });
        });
        return {
          id: x.id,
          yil: x.yil,
          ay: x.ay,
          maas: Number(x.maas || 0),
          hesaba: Number(x.hesaba || 0),
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

  // En son yedek kopyası (sabit isimli)
  const sonDosya = path.resolve(process.cwd(), 'butce-yedek-son.json');
  fs.writeFileSync(sonDosya, JSON.stringify(paket, null, 2), 'utf8');

  console.log(`✅ Yedek başarıyla oluşturuldu: ${ciktiDosyasi}`);
  console.log(`Dosya boyutu: ${fs.statSync(ciktiDosyasi).size} bayt`);
}

calistir().catch(err => {
  console.error('Yedek alma sırasında hata oluştu:', err);
  process.exit(1);
});
