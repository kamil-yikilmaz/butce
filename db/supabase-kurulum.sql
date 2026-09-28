-- ============================================================================
--  Birikim ve Bütçe Defteri · Supabase kurulumu
--  Supabase panelinde  SQL Editor > New query  içine yapıştırıp RUN et.
--  Tek seferlik çalışır; tekrar çalıştırmak güvenlidir (IF NOT EXISTS kullanır).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TABLOLAR
--    Her tabloda user_id var; RLS sayesinde herkes yalnızca kendi satırını görür.
--    id alanları text: uygulama kendi kimliğini üretir, böylece çevrimdışı
--    oluşturulan kayıtlar da sorunsuz yazılır.
-- ----------------------------------------------------------------------------

-- Kur ve genel ayarlar (kullanıcı başına tek satır)
create table if not exists public.ayarlar (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  usd_kur     numeric not null default 0,
  eur_kur     numeric not null default 0,
  kur_tarihi  text    not null default '',
  guncellendi timestamptz not null default now()
);

-- MODÜL 1 · Döviz birikimi (aylık alımlar)
create table if not exists public.doviz_aylar (
  id           text primary key,
  user_id      uuid not null references auth.users(id) on delete cascade,
  yil          int  not null,
  ay           int  not null check (ay between 1 and 12),
  usd          numeric not null default 0,
  usd_tl       numeric not null default 0,
  eur          numeric not null default 0,
  eur_tl       numeric not null default 0,
  ek_tl        numeric not null default 0,
  vergi_dilimi numeric not null default 0,
  usd_dekont   jsonb,
  eur_dekont   jsonb,
  guncellendi  timestamptz not null default now()
);
create unique index if not exists doviz_aylar_donem  on public.doviz_aylar (user_id, yil, ay);

-- MODÜL 2 · Taksitler
create table if not exists public.taksitler (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  ad          text not null default '',
  tutar       numeric not null default 0,
  bas_yil     int not null,
  bas_ay      int not null check (bas_ay between 1 and 12),
  bit_yil     int not null,
  bit_ay      int not null check (bit_ay between 1 and 12),
  guncellendi timestamptz not null default now()
);
create index if not exists taksitler_user on public.taksitler (user_id, bas_yil, bas_ay);

-- MODÜL 2 · Bütçe ayları (maaş ve transfer)
create table if not exists public.butce_aylar (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  yil         int not null,
  ay          int not null check (ay between 1 and 12),
  maas        numeric not null default 0,
  hesaba      numeric not null default 0,
  guncellendi timestamptz not null default now()
);
create unique index if not exists butce_aylar_donem on public.butce_aylar (user_id, yil, ay);

-- MODÜL 2 · Bütçe kalemleri (fatura / diğer gider)
create table if not exists public.butce_kalemler (
  id      text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  ay_id   text not null references public.butce_aylar(id) on delete cascade,
  tur     text not null check (tur in ('fatura','gider')),
  ad      text not null default '',
  tutar   numeric not null default 0,
  sira    int  not null default 0
);
create index if not exists butce_kalemler_ay on public.butce_kalemler (user_id, ay_id, tur, sira);

-- MODÜL 3 · Ödemeler (tekrar eden borç/fatura tanımları)
create table if not exists public.odemeler (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  ad          text not null default '',
  tutar       numeric not null default 0,
  gun         int  not null default 1 check (gun between 1 and 31),
  bas_yil     int not null,
  bas_ay      int not null check (bas_ay between 1 and 12),
  bit_yil     int not null default 0,   -- 0 = süresiz
  bit_ay      int not null default 0,
  guncellendi timestamptz not null default now()
);
create index if not exists odemeler_user on public.odemeler (user_id, gun);

-- MODÜL 3 · Hangi ay ödendi
create table if not exists public.odeme_durum (
  odeme_id text not null references public.odemeler(id) on delete cascade,
  yil      int  not null,
  ay       int  not null check (ay between 1 and 12),
  user_id  uuid not null references auth.users(id) on delete cascade,
  odendi   boolean not null default true,
  primary key (odeme_id, yil, ay)
);
create index if not exists odeme_durum_user on public.odeme_durum (user_id);

-- MODÜL 3 · Aya özel tutar (kart ekstresi her ay değişir)
create table if not exists public.odeme_tutar (
  odeme_id text not null references public.odemeler(id) on delete cascade,
  yil      int  not null,
  ay       int  not null check (ay between 1 and 12),
  user_id  uuid not null references auth.users(id) on delete cascade,
  tutar    numeric not null default 0,
  primary key (odeme_id, yil, ay)
);
create index if not exists odeme_tutar_user on public.odeme_tutar (user_id);

-- ----------------------------------------------------------------------------
-- 2. RLS · satır bazlı güvenlik
--    Bu blok olmadan anon anahtarı bilen herkes her şeyi okur. Zorunlu.
-- ----------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['ayarlar','doviz_aylar','taksitler','butce_aylar',
                           'butce_kalemler','odemeler','odeme_durum','odeme_tutar']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_kendi', t);
    execute format($f$
      create policy %I on public.%I
        for all
        to authenticated
        using (user_id = auth.uid())
        with check (user_id = auth.uid())
    $f$, t||'_kendi', t);
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- 3. DEKONT DEPOSU (Supabase Storage)
--    Dosyalar  dekontlar/<user_id>/<dosya>  yolunda tutulur.
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('dekontlar','dekontlar', false)
on conflict (id) do nothing;

drop policy if exists "dekont kendi klasorum" on storage.objects;
create policy "dekont kendi klasorum"
  on storage.objects for all
  to authenticated
  using      (bucket_id = 'dekontlar' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'dekontlar' and (storage.foldername(name))[1] = auth.uid()::text);

-- ----------------------------------------------------------------------------
-- 4. KONTROL
-- ----------------------------------------------------------------------------
select tablename,
       (select count(*) from pg_policies p
         where p.schemaname='public' and p.tablename=t.tablename) as politika_sayisi,
       rowsecurity as rls_acik
from pg_tables t
where schemaname='public'
  and tablename in ('ayarlar','doviz_aylar','taksitler','butce_aylar',
                    'butce_kalemler','odemeler','odeme_durum','odeme_tutar')
order by tablename;
