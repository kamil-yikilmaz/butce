// scripts/yedekle.js
// Supabase veritabanındaki verileri çekip Bütçe Defteri formatında JSON yedek dosyası oluşturur.

const fs = require('fs');
const path = require('path');

const URL = (process.env.SUPABASE_URL || 'https://vvsoyooedstcrsohqnfj.supabase.co').trim().replace(/\/+$/, '');
const KEY = (process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || '').trim();

if (!KEY) {
  console.error('HATA: SUPABASE_SERVICE_ROLE_KEY tanımlanmamış!');
  process.exit(1);
}

async function get(tablo, query = '') {
  const url = `${URL}/rest/v1/${tablo}?select=*${query ? '&' + query : ''}`;
  try {
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
      console.warn(`[UYARI] ${tablo} okunamadı (${res.status}): ${errText}`);
      return [];
    }
    const data = await res.json();
    return Array.isArray(data) ? data : [];
  } catch (e) {
    console.warn(`[UYARI] ${tablo} isteğinde hata:`, e.message);
    return [];
  }
}

async function calistir() {
  console.log(`Supabase URL: ${URL}`);
  console.log(`Anahtar uzunluğu: ${KEY.length} karakter`);

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

  console.log(`Veri özeti:`);
  console.log(`- Döviz kayıtları: ${dv.length}`);
  console.log(`- Taksitler: ${tk.length}`);
  console.log(`- Bütçe ayları: ${ba.length}`);
  console.log(`- Bütçe kalemleri: ${bk.length}`);
  console.log(`- Ödemeler: ${od.length}`);

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

  console.log(`✅ Yedek başarıyla kaydedildi: ${ciktiDosyasi} (${fs.statSync(ciktiDosyasi).size} bayt)`);
}

calistir().catch(err => {
  console.error('Kritik hata:', err);
  process.exit(1);
});
