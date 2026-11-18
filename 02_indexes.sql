-- Antrian CS/PD: filter parcel menurut status (MO-33)
CREATE INDEX idx_parcel_status ON parcel(status);
-- Daftar parcel per client (MO-20, RLS parcel_milik_client)
CREATE INDEX idx_parcel_client ON parcel(id_client);
-- Parcel per sesi (laporan per sesi, MO-35)
CREATE INDEX idx_parcel_sesi ON parcel(id_sesi);
-- Join pesanan -> parcel (sisa tagihan, laba parcel)
CREATE INDEX idx_pesanan_parcel ON pesanan(id_parcel);
-- Isi batch dan progres terhadap ambang (MO-28)
CREATE INDEX idx_baris_batch ON baris_pesanan(id_batch);
-- Antrian Procurement menurut status baris (MO-22, MO-40)
CREATE INDEX idx_baris_status ON baris_pesanan(status);
-- Join baris -> penawaran (harga termurah, tukar)
CREATE INDEX idx_baris_penawaran ON baris_pesanan(id_penawaran);
-- Cari semua penawaran sebuah distributor (MO-17)
CREATE INDEX idx_penawaran_dist ON penawaran(id_distributor);
-- Cari penawaran per produk set (kartu satuan sudah terlayani UNIQUE)
CREATE INDEX idx_penawaran_set ON penawaran(id_set_kartu);
-- Pencarian produk menurut rarity/seri/karakter (MO-15)
CREATE INDEX idx_kartu_rarity ON kartu_individual(id_rarity);
CREATE INDEX idx_kartu_seri ON kartu_individual(id_seri);
CREATE INDEX idx_kartu_karakter ON kartu_individual(id_karakter);
-- Pelunasan per parcel (sisa tagihan, MO-31)
CREATE INDEX idx_pelunasan_parcel ON pembayaran_pelunasan(id_parcel);
-- Monitor QRIS menurut status (MO-25)
CREATE INDEX idx_dp_status ON pembayaran_dp(status_qris);
CREATE INDEX idx_pelunasan_status ON pembayaran_pelunasan(status_qris);
-- Riwayat status per baris/parcel/batch (MO-32)
CREATE INDEX idx_riwayat_baris ON riwayat_baris(id_pesanan, no_baris);
CREATE INDEX idx_riwayat_parcel ON riwayat_parcel(id_parcel);
CREATE INDEX idx_riwayat_batch ON riwayat_batch(id_batch);

-- BR-10: hanya satu sesi ACTIVE pada satu waktu (indeks unik parsial)
CREATE UNIQUE INDEX uq_satu_sesi_aktif ON sesi_jastip ((true)) WHERE status = 'ACTIVE';
