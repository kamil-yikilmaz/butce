-- ============================================================================
-- Aylık Bütçe: Çoklu Hesaba Gönderilenler (Transferler) Kolonu
-- Supabase SQL Editor içine yapıştırıp "Run" butonuna basın.
-- ============================================================================

-- butce_aylar tablosuna gonderimler (JSONB) kolonunu ekle
ALTER TABLE public.butce_aylar 
ADD COLUMN IF NOT EXISTS gonderimler jsonb DEFAULT '[]'::jsonb;
