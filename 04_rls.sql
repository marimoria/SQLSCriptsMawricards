ALTER TABLE rarity               ENABLE ROW LEVEL SECURITY;
ALTER TABLE seri                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE karakter             ENABLE ROW LEVEL SECURITY;
ALTER TABLE distributor          ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipper              ENABLE ROW LEVEL SECURITY;
ALTER TABLE staf                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE client               ENABLE ROW LEVEL SECURITY;
ALTER TABLE pembelian_kemasan    ENABLE ROW LEVEL SECURITY;
ALTER TABLE rubrik_tarif         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tingkat_tarif        ENABLE ROW LEVEL SECURITY;
ALTER TABLE tingkat_berat        ENABLE ROW LEVEL SECURITY;
ALTER TABLE parameter_berversi   ENABLE ROW LEVEL SECURITY;
ALTER TABLE kartu_individual     ENABLE ROW LEVEL SECURITY;
ALTER TABLE set_kartu            ENABLE ROW LEVEL SECURITY;
ALTER TABLE berisi               ENABLE ROW LEVEL SECURITY;
ALTER TABLE set_karakter         ENABLE ROW LEVEL SECURITY;
ALTER TABLE penawaran            ENABLE ROW LEVEL SECURITY;
ALTER TABLE sesi_jastip          ENABLE ROW LEVEL SECURITY;
ALTER TABLE batch_pengadaan      ENABLE ROW LEVEL SECURITY;
ALTER TABLE parcel               ENABLE ROW LEVEL SECURITY;
ALTER TABLE pesanan              ENABLE ROW LEVEL SECURITY;
ALTER TABLE baris_pesanan        ENABLE ROW LEVEL SECURITY;
ALTER TABLE cek_stok             ENABLE ROW LEVEL SECURITY;
ALTER TABLE penukaran            ENABLE ROW LEVEL SECURITY;
ALTER TABLE pembayaran_dp        ENABLE ROW LEVEL SECURITY;
ALTER TABLE pembayaran_pelunasan ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund               ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaksi_shopee     ENABLE ROW LEVEL SECURITY;
ALTER TABLE laporan_staf         ENABLE ROW LEVEL SECURITY;
ALTER TABLE riwayat_baris        ENABLE ROW LEVEL SECURITY;
ALTER TABLE riwayat_parcel       ENABLE ROW LEVEL SECURITY;
ALTER TABLE riwayat_batch        ENABLE ROW LEVEL SECURITY;

-- 1. Client hanya melihat barisnya sendiri
CREATE POLICY client_lihat_diri ON client
  FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid());

-- 2. Client hanya melihat parcel miliknya
CREATE POLICY parcel_milik_client ON parcel
  FOR SELECT TO authenticated
  USING (id_client IN (SELECT id_client FROM client WHERE auth_user_id = auth.uid()));

-- 3. Client hanya melihat pesanan di parcel miliknya
CREATE POLICY pesanan_milik_client ON pesanan
  FOR SELECT TO authenticated
  USING (id_parcel IN (SELECT p.id_parcel FROM parcel p
                       JOIN client c ON c.id_client = p.id_client
                       WHERE c.auth_user_id = auth.uid()));

-- 4. Katalog produk bersifat publik (anon dan authenticated)
CREATE POLICY katalog_kartu ON kartu_individual
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY katalog_set ON set_kartu
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY katalog_rarity ON rarity
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY katalog_seri ON seri
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY katalog_karakter ON karakter
  FOR SELECT TO anon, authenticated USING (true);
