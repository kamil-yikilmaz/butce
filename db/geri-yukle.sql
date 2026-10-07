DO $$
DECLARE
  v_uid uuid;
BEGIN
  SELECT id INTO v_uid FROM auth.users WHERE lower(email) = 'kmlyklmz@gmail.com' LIMIT 1;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Kullanıcı bulunamadı!';
  END IF;

  -- Ayarlar
  INSERT INTO public.ayarlar (user_id, usd_kur, eur_kur, kur_tarihi, guncellendi)
  VALUES (v_uid, 48.2238, 55.9713, '03.09.2026', now())
  ON CONFLICT (user_id) DO UPDATE SET usd_kur=EXCLUDED.usd_kur, eur_kur=EXCLUDED.eur_kur, kur_tarihi=EXCLUDED.kur_tarihi;

  INSERT INTO public.doviz_aylar (id, user_id, yil, ay, usd, usd_tl, eur, eur_tl, ek_tl, vergi_dilimi, guncellendi)
  VALUES ('r1', v_uid, 2026, 4, 150, 6723.96, 0, 0, 0, 27, now())
  ON CONFLICT (id) DO UPDATE SET usd=EXCLUDED.usd, usd_tl=EXCLUDED.usd_tl, eur=EXCLUDED.eur, eur_tl=EXCLUDED.eur_tl, ek_tl=EXCLUDED.ek_tl, vergi_dilimi=EXCLUDED.vergi_dilimi;
  INSERT INTO public.doviz_aylar (id, user_id, yil, ay, usd, usd_tl, eur, eur_tl, ek_tl, vergi_dilimi, guncellendi)
  VALUES ('r2', v_uid, 2026, 5, 150, 6819.4, 0, 0, 0, 27, now())
  ON CONFLICT (id) DO UPDATE SET usd=EXCLUDED.usd, usd_tl=EXCLUDED.usd_tl, eur=EXCLUDED.eur, eur_tl=EXCLUDED.eur_tl, ek_tl=EXCLUDED.ek_tl, vergi_dilimi=EXCLUDED.vergi_dilimi;
  INSERT INTO public.doviz_aylar (id, user_id, yil, ay, usd, usd_tl, eur, eur_tl, ek_tl, vergi_dilimi, guncellendi)
  VALUES ('r3', v_uid, 2026, 6, 150, 6935.7, 400, 21308.16, 0, 27, now())
  ON CONFLICT (id) DO UPDATE SET usd=EXCLUDED.usd, usd_tl=EXCLUDED.usd_tl, eur=EXCLUDED.eur, eur_tl=EXCLUDED.eur_tl, ek_tl=EXCLUDED.ek_tl, vergi_dilimi=EXCLUDED.vergi_dilimi;
  INSERT INTO public.doviz_aylar (id, user_id, yil, ay, usd, usd_tl, eur, eur_tl, ek_tl, vergi_dilimi, guncellendi)
  VALUES ('r4', v_uid, 2026, 7, 150, 7044.46, 400, 21478.52, 0, 27, now())
  ON CONFLICT (id) DO UPDATE SET usd=EXCLUDED.usd, usd_tl=EXCLUDED.usd_tl, eur=EXCLUDED.eur, eur_tl=EXCLUDED.eur_tl, ek_tl=EXCLUDED.ek_tl, vergi_dilimi=EXCLUDED.vergi_dilimi;
  INSERT INTO public.doviz_aylar (id, user_id, yil, ay, usd, usd_tl, eur, eur_tl, ek_tl, vergi_dilimi, guncellendi)
  VALUES ('r5', v_uid, 2026, 8, 150, 7173.8, 400, 22072.16, 0, 27, now())
  ON CONFLICT (id) DO UPDATE SET usd=EXCLUDED.usd, usd_tl=EXCLUDED.usd_tl, eur=EXCLUDED.eur, eur_tl=EXCLUDED.eur_tl, ek_tl=EXCLUDED.ek_tl, vergi_dilimi=EXCLUDED.vergi_dilimi;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t01', v_uid, 'Tatil', 6500, 2025, 7, 2026, 3, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t02', v_uid, 'Ömer LCW okul', 196, 2026, 1, 2026, 3, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t03', v_uid, 'Hilal elbise', 1000, 2025, 10, 2026, 3, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t04', v_uid, 'Metin kışlık', 435, 2025, 10, 2026, 3, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t05', v_uid, 'Ömer ayakkabı', 500, 2026, 4, 2026, 6, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t06', v_uid, 'Fincan', 235, 2026, 4, 2026, 6, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t07', v_uid, 'Akbank', 5833, 2025, 12, 2026, 5, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t08', v_uid, 'Araba', 18500, 2025, 7, 2028, 6, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t09', v_uid, 'Kahve makinası', 777, 2026, 4, 2026, 12, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t10', v_uid, 'Metin & Ömer bayramlık', 295, 2026, 3, 2026, 8, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t11', v_uid, 'LCW okul bayram', 400, 2026, 5, 2026, 10, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('t12', v_uid, 'LCW Kamil', 367, 2026, 6, 2026, 11, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.taksitler (id, user_id, ad, tutar, bas_yil, bas_ay, bit_yil, bit_ay, guncellendi)
  VALUES ('tmth18uwf7is', v_uid, 'Aidat', 1750, 2026, 8, 2026, 8, now())
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar, bas_yil=EXCLUDED.bas_yil, bas_ay=EXCLUDED.bas_ay, bit_yil=EXCLUDED.bit_yil, bit_ay=EXCLUDED.bit_ay;
  INSERT INTO public.butce_aylar (id, user_id, yil, ay, maas, hesaba, guncellendi)
  VALUES ('a202608', v_uid, 2026, 8, 77000, 23270, now())
  ON CONFLICT (id) DO UPDATE SET maas=EXCLUDED.maas, hesaba=EXCLUDED.hesaba;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_f_1', v_uid, 'a202608', 'fatura', 'İnternet', 870, 1)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_f_2', v_uid, 'a202608', 'fatura', 'Elektrik', 375, 2)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_f_3', v_uid, 'a202608', 'fatura', 'Gaz', 95, 3)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_f_4', v_uid, 'a202608', 'fatura', 'Su', 500, 4)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_g_1', v_uid, 'a202608', 'gider', 'Halı', 2150, 1)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_g_2', v_uid, 'a202608', 'gider', 'Nakit', 300, 2)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_g_3', v_uid, 'a202608', 'gider', 'Bamya', 400, 3)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_g_4', v_uid, 'a202608', 'gider', 'Kimlik', 220, 4)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_g_5', v_uid, 'a202608', 'gider', 'Amazon deterjan', 1785, 5)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;
  INSERT INTO public.butce_kalemler (id, user_id, ay_id, tur, ad, tutar, sira)
  VALUES ('a202608_g_6', v_uid, 'a202608', 'gider', 'Seval Hediye', 500, 6)
  ON CONFLICT (id) DO UPDATE SET ad=EXCLUDED.ad, tutar=EXCLUDED.tutar;

  RAISE NOTICE 'Tüm veriler başarıyla geri yüklendi!';
END $$;
