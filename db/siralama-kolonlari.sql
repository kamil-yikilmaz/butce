-- ============================================================================
-- Sıralama Kolonları (Taksitler ve Ödemeler için 'sira' alanı)
-- Supabase SQL Editor içine yapıştırıp "Run" butonuna basın.
-- ============================================================================

-- 1. Taksitler tablosuna 'sira' kolonu ekle
ALTER TABLE public.taksitler ADD COLUMN IF NOT EXISTS sira int DEFAULT 0;

-- 2. Ödemeler tablosuna 'sira' kolonu ekle
ALTER TABLE public.odemeler ADD COLUMN IF NOT EXISTS sira int DEFAULT 0;

-- Sıralama indeksleri
CREATE INDEX IF NOT EXISTS taksitler_user_sira ON public.taksitler (user_id, sira);
CREATE INDEX IF NOT EXISTS odemeler_user_sira ON public.odemeler (user_id, sira);
