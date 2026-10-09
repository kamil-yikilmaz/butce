-- ============================================================================
-- Kullanıcı Bazlı Güvenlik (RLS) ve Veri İzolasyonu Ayarı
-- Supabase SQL Editor içine yapıştırıp "Run" butonuna basın.
-- ============================================================================

-- 1. Tüm tablolarda Satır Bazlı Güvenliği (RLS) Aç
ALTER TABLE public.ayarlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doviz_aylar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taksitler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.butce_aylar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.butce_kalemler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odemeler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odeme_durum ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odeme_tutar ENABLE ROW LEVEL SECURITY;

-- 2. Her kullanıcıya YALNIZCA kendi verilerini okuma/yazma/silme izni ver
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['ayarlar','doviz_aylar','taksitler','butce_aylar',
                           'butce_kalemler','odemeler','odeme_durum','odeme_tutar']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t||'_kendi', t);
    EXECUTE format($f$
      CREATE POLICY %I ON public.%I
        FOR ALL
        TO authenticated
        USING (user_id = auth.uid())
        WITH CHECK (user_id = auth.uid())
    $f$, t||'_kendi', t);
  END LOOP;
END $$;

-- 3. Dekont Deposu (Storage) için Kullanıcı İzolasyonu
INSERT INTO storage.buckets (id, name, public)
VALUES ('dekontlar','dekontlar', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "dekont kendi klasorum" ON storage.objects;
CREATE POLICY "dekont kendi klasorum"
  ON storage.objects FOR ALL
  TO authenticated
  USING      (bucket_id = 'dekontlar' AND (storage.foldername(name))[1] = auth.uid()::text)
  WITH CHECK (bucket_id = 'dekontlar' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 4. KONTROL (Sonuç tablosunda her tablonun karşısında rls_acik = true görünmelidir)
SELECT 
  tablename,
  (SELECT count(*) FROM pg_policies p WHERE p.schemaname='public' AND p.tablename=t.tablename) AS politika_sayisi,
  rowsecurity AS rls_acik
FROM pg_tables t
WHERE schemaname='public'
  AND tablename IN ('ayarlar','doviz_aylar','taksitler','butce_aylar',
                    'butce_kalemler','odemeler','odeme_durum','odeme_tutar')
ORDER BY tablename;
