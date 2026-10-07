-- ============================================================================
-- Şifresiz ve Kesintisiz Supabase Ayarı
-- Supabase SQL Editor içine yapıştırıp "Run" butonuna basın.
-- ============================================================================

-- 1. Foreign key kısıtlamalarını kaldır
-- (Böylece kullanıcı silinse dahi verileriniz ASLA silinmez!)
ALTER TABLE public.ayarlar DROP CONSTRAINT IF EXISTS ayarlar_user_id_fkey;
ALTER TABLE public.doviz_aylar DROP CONSTRAINT IF EXISTS doviz_aylar_user_id_fkey;
ALTER TABLE public.taksitler DROP CONSTRAINT IF EXISTS taksitler_user_id_fkey;
ALTER TABLE public.butce_aylar DROP CONSTRAINT IF EXISTS butce_aylar_user_id_fkey;
ALTER TABLE public.butce_kalemler DROP CONSTRAINT IF EXISTS butce_kalemler_user_id_fkey;
ALTER TABLE public.odemeler DROP CONSTRAINT IF EXISTS odemeler_user_id_fkey;
ALTER TABLE public.odeme_durum DROP CONSTRAINT IF EXISTS odeme_durum_user_id_fkey;
ALTER TABLE public.odeme_tutar DROP CONSTRAINT IF EXISTS odeme_tutar_user_id_fkey;

-- 2. user_id alanını isteğe bağlı yap (Varsayılan sabit ID ata)
ALTER TABLE public.ayarlar ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.doviz_aylar ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.taksitler ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.butce_aylar ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.butce_kalemler ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.odemeler ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.odeme_durum ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.odeme_tutar ALTER COLUMN user_id DROP NOT NULL;

-- 3. RLS kısıtlamalarını devre dışı bırak (Şifresiz doğrudan okuma ve yazma izni)
ALTER TABLE public.ayarlar DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.doviz_aylar DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.taksitler DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.butce_aylar DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.butce_kalemler DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.odemeler DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.odeme_durum DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.odeme_tutar DISABLE ROW LEVEL SECURITY;
