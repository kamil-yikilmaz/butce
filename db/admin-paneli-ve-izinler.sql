-- ============================================================================
-- Admin Paneli, Çoklu Kullanıcı ve Modül Yetkilendirme Sistemi
-- Supabase SQL Editor içine yapıştırıp "Run" butonuna basın.
-- ============================================================================

-- 1. Admin ID Belirleme Fonksiyonu
CREATE OR REPLACE FUNCTION public.admin_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT id FROM auth.users WHERE email = 'kmlyklmz@gmail.com' LIMIT 1;
$$;

-- 2. Kullanıcı İzinleri Tablosu
CREATE TABLE IF NOT EXISTS public.kullanici_izinleri (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  modul text NOT NULL, -- 'doviz', 'butce', 'odemeler'
  erisim boolean NOT NULL DEFAULT true, -- modülü görebilir mi?
  veri_modu text NOT NULL DEFAULT 'ozel', -- 'ortak' (admin verisi) veya 'ozel' (kendi verisi)
  guncellendi timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, modul)
);

-- İzin tablosu için RLS
ALTER TABLE public.kullanici_izinleri ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "izinler_admin_hepsi" ON public.kullanici_izinleri;
CREATE POLICY "izinler_admin_hepsi" ON public.kullanici_izinleri
  FOR ALL TO authenticated
  USING (auth.jwt() ->> 'email' = 'kmlyklmz@gmail.com')
  WITH CHECK (auth.jwt() ->> 'email' = 'kmlyklmz@gmail.com');

DROP POLICY IF EXISTS "izinler_kullanici_kendi" ON public.kullanici_izinleri;
CREATE POLICY "izinler_kullanici_kendi" ON public.kullanici_izinleri
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- 3. Adminin Tüm Kullanıcıları Listelemesi İçin Güvenli Fonksiyon (RPC)
CREATE OR REPLACE FUNCTION public.admin_kullanicilari_getir()
RETURNS TABLE (
  id uuid,
  email text,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Yalnızca admin çağırabilir
  IF auth.jwt() ->> 'email' = 'kmlyklmz@gmail.com' THEN
    RETURN QUERY 
    SELECT u.id, u.email::text, u.created_at 
    FROM auth.users u
    ORDER BY u.created_at ASC;
  ELSE
    RAISE EXCEPTION 'Yetkisiz erişim';
  END IF;
END;
$$;

-- 4. Modül Tablolarında Ortak & Özel Veri Güvenlik Politikaları (RLS)

-- A. DÖVİZ BİRİKİMİ TABLOLARI ('doviz')
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['ayarlar', 'doviz_aylar']
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t||'_kendi', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t||'_erisim', t);
    EXECUTE format($f$
      CREATE POLICY %I ON public.%I
        FOR ALL TO authenticated
        USING (
          user_id = auth.uid()
          OR (
            user_id = public.admin_id()
            AND EXISTS (
              SELECT 1 FROM public.kullanici_izinleri ki
              WHERE ki.user_id = auth.uid()
                AND ki.modul = 'doviz'
                AND ki.erisim = true
                AND ki.veri_modu = 'ortak'
            )
          )
        )
        WITH CHECK (
          user_id = auth.uid()
          OR (
            user_id = public.admin_id()
            AND EXISTS (
              SELECT 1 FROM public.kullanici_izinleri ki
              WHERE ki.user_id = auth.uid()
                AND ki.modul = 'doviz'
                AND ki.erisim = true
                AND ki.veri_modu = 'ortak'
            )
          )
        )
    $f$, t||'_erisim', t);
  END LOOP;
END $$;

-- B. AYLIK BÜTÇE TABLOLARI ('butce')
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['taksitler', 'butce_aylar', 'butce_kalemler']
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t||'_kendi', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t||'_erisim', t);
    EXECUTE format($f$
      CREATE POLICY %I ON public.%I
        FOR ALL TO authenticated
        USING (
          user_id = auth.uid()
          OR (
            user_id = public.admin_id()
            AND EXISTS (
              SELECT 1 FROM public.kullanici_izinleri ki
              WHERE ki.user_id = auth.uid()
                AND ki.modul = 'butce'
                AND ki.erisim = true
                AND ki.veri_modu = 'ortak'
            )
          )
        )
        WITH CHECK (
          user_id = auth.uid()
          OR (
            user_id = public.admin_id()
            AND EXISTS (
              SELECT 1 FROM public.kullanici_izinleri ki
              WHERE ki.user_id = auth.uid()
                AND ki.modul = 'butce'
                AND ki.erisim = true
                AND ki.veri_modu = 'ortak'
            )
          )
        )
    $f$, t||'_erisim', t);
  END LOOP;
END $$;

-- C. ÖDEMELER TABLOLARI ('odemeler')
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['odemeler', 'odeme_durum', 'odeme_tutar']
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t||'_kendi', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t||'_erisim', t);
    EXECUTE format($f$
      CREATE POLICY %I ON public.%I
        FOR ALL TO authenticated
        USING (
          user_id = auth.uid()
          OR (
            user_id = public.admin_id()
            AND EXISTS (
              SELECT 1 FROM public.kullanici_izinleri ki
              WHERE ki.user_id = auth.uid()
                AND ki.modul = 'odemeler'
                AND ki.erisim = true
                AND ki.veri_modu = 'ortak'
            )
          )
        )
        WITH CHECK (
          user_id = auth.uid()
          OR (
            user_id = public.admin_id()
            AND EXISTS (
              SELECT 1 FROM public.kullanici_izinleri ki
              WHERE ki.user_id = auth.uid()
                AND ki.modul = 'odemeler'
                AND ki.erisim = true
                AND ki.veri_modu = 'ortak'
            )
          )
        )
    $f$, t||'_erisim', t);
  END LOOP;
END $$;

-- 5. KONTROL SORGUSU
SELECT tablename, rowsecurity AS rls_acik FROM pg_tables 
WHERE schemaname='public' AND tablename IN (
  'kullanici_izinleri','ayarlar','doviz_aylar','taksitler','butce_aylar','butce_kalemler','odemeler','odeme_durum','odeme_tutar'
);
