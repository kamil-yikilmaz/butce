-- ============================================================================
-- Modül 4: Patates Dağıtım & Sipariş Takibi
-- Supabase SQL Editor sekmesinde çalıştırın.
-- ============================================================================

-- 1. Patates Verileri Tablosu
CREATE TABLE IF NOT EXISTS public.patates_veriler (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  veri jsonb NOT NULL DEFAULT '{}'::jsonb,
  guncellendi timestamptz NOT NULL DEFAULT now()
);

-- 2. Satır Düzeyi Güvenlik (RLS)
ALTER TABLE public.patates_veriler ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "patates_veriler_erisim" ON public.patates_veriler;
CREATE POLICY "patates_veriler_erisim" ON public.patates_veriler
  FOR ALL TO authenticated
  USING (
    user_id = auth.uid()
    OR (
      user_id = public.admin_id()
      AND EXISTS (
        SELECT 1 FROM public.kullanici_izinleri ki
        WHERE ki.user_id = auth.uid()
          AND ki.modul = 'patates'
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
          AND ki.modul = 'patates'
          AND ki.erisim = true
          AND ki.veri_modu = 'ortak'
      )
    )
  );
