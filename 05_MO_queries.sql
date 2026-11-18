-- MO.1

SELECT v.id_produk, v.jenis, v.nama, r.nama_rarity, s.nama_seri, v.harga_jual, v.url_gambar
    FROM v_produk v
    JOIN rarity r ON r.id_rarity = v.id_rarity
    JOIN seri s ON s.id_seri = v.id_seri
    ORDER BY v.id_produk;

-- MO.2

SELECT d.id_distributor, d.nama_toko, d.platform, COUNT(p.id_penawaran) AS jumlah_penawaran
    FROM distributor d
    LEFT JOIN penawaran p ON p.id_distributor = d.id_distributor
    GROUP BY d.id_distributor, d.nama_toko, d.platform
    ORDER BY d.id_distributor;

-- MO.3

SELECT p.id_penawaran, v.jenis, v.nama, d.nama_toko, p.harga_rmb, p.ketersediaan, p.minimum_qty, p.tautan
    FROM penawaran p
    JOIN v_produk v ON v.id_produk = COALESCE(p.id_kartu_individual, p.id_set_kartu)
    JOIN distributor d ON d.id_distributor = p.id_distributor
    ORDER BY p.id_penawaran;

-- MO.4

SELECT sh.nama_shipper, rt.id_rubrik, rt.berlaku_mulai, rt.berlaku_sampai, 'PAJAK_JASA' AS jenis_tingkat,
       tt.no_tingkat, tt.harga_min_rmb AS batas_bawah, tt.harga_maks_rmb AS batas_atas, tt.persen_markup AS nilai
    FROM shipper sh
    JOIN rubrik_tarif rt ON rt.id_shipper = sh.id_shipper
    JOIN tingkat_tarif tt ON tt.id_rubrik = rt.id_rubrik
UNION ALL
SELECT sh.nama_shipper, rt.id_rubrik, rt.berlaku_mulai, rt.berlaku_sampai, 'BERAT',
       tb.no_tingkat, tb.berat_min_gram, tb.berat_maks_gram, tb.tarif_per_gram
    FROM shipper sh
    JOIN rubrik_tarif rt ON rt.id_shipper = sh.id_shipper
    JOIN tingkat_berat tb ON tb.id_rubrik = rt.id_rubrik
    ORDER BY nama_shipper, id_rubrik, jenis_tingkat, no_tingkat;

-- MO.5

SELECT id_client, nama_lengkap, username_tiktok, no_whatsapp, email,
       auth_user_id IS NOT NULL AS punya_akun_login
    FROM client
    ORDER BY id_client;

-- MO.6

SELECT ps.id_pesanan, c.username_tiktok, s.nama_sesi, ps.waktu_pesan,
       COUNT(*) AS jumlah_baris, SUM(bp.harga_jual * bp.jumlah) AS total_harga
    FROM pesanan ps
    JOIN parcel pc ON pc.id_parcel = ps.id_parcel
    JOIN client c ON c.id_client = pc.id_client
    JOIN sesi_jastip s ON s.id_sesi = pc.id_sesi
    JOIN baris_pesanan bp ON bp.id_pesanan = ps.id_pesanan
    GROUP BY ps.id_pesanan, c.username_tiktok, s.nama_sesi, ps.waktu_pesan
    ORDER BY ps.id_pesanan;

-- MO.7

SELECT pc.id_parcel, c.username_tiktok, s.nama_sesi, pc.status, pc.waktu_lengkap,
       pc.biaya_kemasan, pk.ukuran AS ukuran_kemasan
    FROM parcel pc
    JOIN client c ON c.id_client = pc.id_client
    JOIN sesi_jastip s ON s.id_sesi = pc.id_sesi
    LEFT JOIN pembelian_kemasan pk ON pk.id_pembelian = pc.id_pembelian
    ORDER BY pc.id_parcel;

-- MO.8

SELECT 'DP' AS jenis, id_pembayaran, id_pesanan AS id_rujukan, nominal, status_qris,
       waktu_dibuat, waktu_kedaluwarsa, waktu_dibayar
    FROM pembayaran_dp
UNION ALL
SELECT 'PELUNASAN', id_pembayaran, id_parcel, nominal, status_qris,
       waktu_dibuat, waktu_kedaluwarsa, waktu_dibayar
    FROM pembayaran_pelunasan
    ORDER BY waktu_dibuat;

-- MO.9

SELECT s.id_sesi, s.nama_sesi, sh.nama_shipper, s.status, s.waktu_mulai, s.waktu_tutup,
       st.nama_staf AS ditutup_oleh
    FROM sesi_jastip s
    JOIN shipper sh ON sh.id_shipper = s.id_shipper
    LEFT JOIN staf st ON st.id_staf = s.ditutup_oleh
    ORDER BY s.waktu_mulai;

-- MO.10

SELECT b.id_batch, s.nama_sesi, b.status, b.waktu_dipesan, COUNT(bp.no_baris) AS jumlah_baris
    FROM batch_pengadaan b
    JOIN sesi_jastip s ON s.id_sesi = b.id_sesi
    LEFT JOIN baris_pesanan bp ON bp.id_batch = b.id_batch
    GROUP BY b.id_batch, s.nama_sesi, b.status, b.waktu_dipesan
    ORDER BY b.id_batch;

-- MO.11

SELECT t.id_parcel, c.username_tiktok, t.no_pesanan_shopee, t.kode_spx, t.nominal_listing,
       t.waktu_transaksi, st.nama_staf AS dicatat_oleh
    FROM transaksi_shopee t
    JOIN parcel pc ON pc.id_parcel = t.id_parcel
    JOIN client c ON c.id_client = pc.id_client
    JOIN staf st ON st.id_staf = t.dicatat_oleh
    ORDER BY t.waktu_transaksi;

-- MO.12

SELECT pk.id_pembelian, pk.tanggal_beli, pk.sumber, pk.ukuran, pk.jumlah, pk.total_biaya,
       st.nama_staf AS dicatat_oleh
    FROM pembelian_kemasan pk
    JOIN staf st ON st.id_staf = pk.dicatat_oleh
    ORDER BY pk.tanggal_beli, pk.id_pembelian;

-- MO.13

SELECT id_staf, nama_staf, email, peran, auth_user_id IS NOT NULL AS punya_akun_login
    FROM staf
    ORDER BY id_staf;

-- MO.14

SELECT pb.nama_parameter, pb.nilai, COALESCE(sh.nama_shipper, 'Semua shipper') AS shipper,
       pb.berlaku_mulai, st.nama_staf AS ditetapkan_oleh
    FROM parameter_berversi pb
    LEFT JOIN shipper sh ON sh.id_shipper = pb.id_shipper
    JOIN staf st ON st.id_staf = pb.ditetapkan_oleh
    ORDER BY pb.nama_parameter, pb.berlaku_mulai;

-- MO.15

SELECT k.id_produk, k.nama, r.nama_rarity, s.nama_seri, c.nama_karakter, k.harga_jual
    FROM kartu_individual k
    JOIN rarity r ON r.id_rarity = k.id_rarity
    JOIN seri s ON s.id_seri = k.id_seri
    JOIN karakter c ON c.id_karakter = k.id_karakter
    WHERE r.nama_rarity = 'SGR'
      AND s.nama_seri = 'Moon Edition 12'
      AND c.nama_karakter = 'Fluttershy'
    ORDER BY k.nama;

-- MO.16

SELECT d.nama_toko, d.platform,
       COUNT(p.id_penawaran) FILTER (WHERE p.ketersediaan) AS penawaran_aktif,
       MIN(p.harga_rmb) AS harga_rmb_termurah
    FROM distributor d
    LEFT JOIN penawaran p ON p.id_distributor = d.id_distributor
    WHERE d.nama_toko ILIKE '%xiao%'
    GROUP BY d.nama_toko, d.platform
    ORDER BY d.nama_toko;

-- MO.17

SELECT DISTINCT ON (k.id_produk) k.id_produk, k.nama, d.nama_toko, p.harga_rmb
    FROM kartu_individual k
    JOIN penawaran p ON p.id_kartu_individual = k.id_produk
    JOIN distributor d ON d.id_distributor = p.id_distributor
    WHERE p.ketersediaan = true
    ORDER BY k.id_produk, p.harga_rmb ASC;

-- MO.18

SELECT id_client, nama_lengkap, username_tiktok, no_whatsapp, email
    FROM client
    WHERE username_tiktok ILIKE '%ie%' OR nama_lengkap ILIKE '%ie%'
    ORDER BY username_tiktok;

-- MO.19

SELECT ps.id_pesanan, ps.waktu_pesan, s.nama_sesi,
       d.nominal AS nominal_dp, d.status_qris AS status_dp, d.waktu_dibayar AS dp_dibayar,
       pl.nominal AS nominal_pelunasan, pl.status_qris AS status_pelunasan
    FROM pesanan ps
    JOIN parcel pc ON pc.id_parcel = ps.id_parcel
    JOIN client c ON c.id_client = pc.id_client
    JOIN sesi_jastip s ON s.id_sesi = pc.id_sesi
    LEFT JOIN pembayaran_dp d ON d.id_pesanan = ps.id_pesanan
    LEFT JOIN pembayaran_pelunasan pl ON pl.id_parcel = pc.id_parcel
    WHERE c.username_tiktok = 'crepe'
    ORDER BY ps.waktu_pesan;

-- MO.20

SELECT c.nama_lengkap, c.username_tiktok, s.nama_sesi, p.id_parcel, p.status
    FROM parcel p
    JOIN client c ON c.id_client = p.id_client
    JOIN sesi_jastip s ON s.id_sesi = p.id_sesi
    ORDER BY s.waktu_mulai DESC, c.nama_lengkap;

-- MO.21

SELECT b.id_batch, s.nama_sesi, b.status, b.waktu_dipesan,
       COUNT(bp.no_baris) AS jumlah_baris, SUM(bp.harga_dasar_rmb * bp.jumlah) AS total_rmb
    FROM batch_pengadaan b
    JOIN sesi_jastip s ON s.id_sesi = b.id_sesi
    LEFT JOIN baris_pesanan bp ON bp.id_batch = b.id_batch
    WHERE s.status = 'ACTIVE'
    GROUP BY b.id_batch, s.nama_sesi, b.status, b.waktu_dipesan
    ORDER BY b.id_batch;

-- MO.22

SELECT bp.id_pesanan, bp.no_baris, c.username_tiktok, v.nama, bp.status
    FROM baris_pesanan bp
    JOIN penawaran p ON p.id_penawaran = bp.id_penawaran
    JOIN v_produk v ON v.id_produk = COALESCE(p.id_kartu_individual, p.id_set_kartu)
    JOIN pesanan ps ON ps.id_pesanan = bp.id_pesanan
    JOIN parcel pc ON pc.id_parcel = ps.id_parcel
    JOIN client c ON c.id_client = pc.id_client
    ORDER BY bp.id_pesanan, bp.no_baris;

-- MO.23

SELECT s.nama_sesi, p.status, COUNT(*) AS jumlah_parcel
    FROM parcel p
    JOIN sesi_jastip s ON s.id_sesi = p.id_sesi
    GROUP BY s.nama_sesi, s.waktu_mulai, p.status
    ORDER BY s.waktu_mulai,
             array_position(ARRAY['OPEN','INCOMPLETE','COMPLETE','SETTLED','CODE_ISSUED',
                                  'PACKED','HANDED_OVER','RECEIVED']::varchar[], p.status);

-- MO.24

SELECT s.nama_sesi, b.status, COUNT(*) AS jumlah_batch
    FROM batch_pengadaan b
    JOIN sesi_jastip s ON s.id_sesi = b.id_sesi
    GROUP BY s.nama_sesi, s.waktu_mulai, b.status
    ORDER BY s.waktu_mulai, b.status;

-- MO.25

SELECT 'DP' AS jenis, status_qris, COUNT(*) AS jumlah, SUM(nominal) AS total_nominal
    FROM pembayaran_dp GROUP BY status_qris
UNION ALL
SELECT 'PELUNASAN', status_qris, COUNT(*), SUM(nominal)
    FROM pembayaran_pelunasan GROUP BY status_qris
    ORDER BY jenis, status_qris;

-- MO.26

SELECT d.nama_toko,
       COUNT(*) FILTER (WHERE p.ketersediaan) AS tersedia,
       COUNT(*) FILTER (WHERE NOT p.ketersediaan) AS habis,
       COUNT(*) AS total_penawaran
    FROM distributor d
    JOIN penawaran p ON p.id_distributor = d.id_distributor
    GROUP BY d.nama_toko
    ORDER BY total_penawaran DESC;

-- MO.27

SELECT DISTINCT ON (cs.id_pesanan, cs.no_baris)
       cs.id_pesanan, cs.no_baris, cs.no_cek, cs.tahap, cs.hasil, st.nama_staf AS dicek_oleh, cs.waktu_cek
    FROM cek_stok cs
    JOIN staf st ON st.id_staf = cs.id_staf
    ORDER BY cs.id_pesanan, cs.no_baris, cs.no_cek DESC;

-- MO.28

WITH ambang AS (
    SELECT nilai FROM parameter_berversi
    WHERE nama_parameter = 'AMBANG_BATCH'
    ORDER BY berlaku_mulai DESC LIMIT 1)
SELECT b.id_batch, s.nama_sesi,
       SUM(bp.harga_dasar_rmb * bp.jumlah) AS total_rmb,
       a.nilai AS ambang_rmb,
       ROUND(100 * SUM(bp.harga_dasar_rmb * bp.jumlah) / a.nilai, 1) AS progres_persen
    FROM batch_pengadaan b
    JOIN sesi_jastip s ON s.id_sesi = b.id_sesi
    JOIN baris_pesanan bp ON bp.id_batch = b.id_batch
    CROSS JOIN ambang a
    WHERE b.status = 'COLLECTING'
    GROUP BY b.id_batch, s.nama_sesi, a.nilai;

-- MO.29

SELECT pk.ukuran,
       SUM(pk.jumlah) AS total_dibeli,
       (SELECT COUNT(*) FROM parcel p
            JOIN pembelian_kemasan x ON x.id_pembelian = p.id_pembelian
            WHERE x.ukuran = pk.ukuran) AS terpakai,
       SUM(pk.jumlah) - (SELECT COUNT(*) FROM parcel p
            JOIN pembelian_kemasan x ON x.id_pembelian = p.id_pembelian
            WHERE x.ukuran = pk.ukuran) AS sisa_stok
    FROM pembelian_kemasan pk
    GROUP BY pk.ukuran
    ORDER BY pk.ukuran;

-- MO.30

SELECT s.nama_sesi, sh.nama_shipper, s.status, s.waktu_mulai, s.waktu_tutup,
       (SELECT COUNT(*) FROM parcel p WHERE p.id_sesi = s.id_sesi) AS jumlah_parcel,
       (SELECT COUNT(*) FROM batch_pengadaan b WHERE b.id_sesi = s.id_sesi) AS jumlah_batch
    FROM sesi_jastip s
    JOIN shipper sh ON sh.id_shipper = s.id_shipper
    ORDER BY s.waktu_mulai;

-- MO.31

WITH tagihan AS (
    SELECT ps.id_parcel, SUM(bp.harga_jual * bp.jumlah) AS total
    FROM baris_pesanan bp JOIN pesanan ps ON ps.id_pesanan = bp.id_pesanan
    WHERE bp.status NOT IN ('KEDALUWARSA','REFUNDED','STOK_HABIS')
    GROUP BY ps.id_parcel),
dp AS (
    SELECT ps.id_parcel, SUM(d.nominal) AS dibayar
    FROM pembayaran_dp d JOIN pesanan ps ON ps.id_pesanan = d.id_pesanan
    WHERE d.status_qris = 'PAID' GROUP BY ps.id_parcel),
rf AS (
    SELECT ps.id_parcel, SUM(r.nominal) AS kembali
    FROM refund r JOIN pesanan ps ON ps.id_pesanan = r.id_pesanan
    GROUP BY ps.id_parcel),
lunas AS (
    SELECT id_parcel, SUM(nominal) AS dibayar
    FROM pembayaran_pelunasan WHERE status_qris = 'PAID' GROUP BY id_parcel)
SELECT p.id_parcel, p.status, t.total,
       COALESCE(d.dibayar, 0) - COALESCE(rf.kembali, 0) AS dp_bersih,
       COALESCE(l.dibayar, 0) AS pelunasan,
       t.total - (COALESCE(d.dibayar, 0) - COALESCE(rf.kembali, 0)) - COALESCE(l.dibayar, 0) AS sisa
    FROM parcel p
    JOIN tagihan t ON t.id_parcel = p.id_parcel
    LEFT JOIN dp d ON d.id_parcel = p.id_parcel
    LEFT JOIN rf ON rf.id_parcel = p.id_parcel
    LEFT JOIN lunas l ON l.id_parcel = p.id_parcel
    ORDER BY p.id_parcel;

-- MO.32

SELECT 'BARIS' AS objek, rb.id_pesanan || '-' || rb.no_baris AS id_objek, rb.status_lama, rb.status_baru,
       rb.waktu, COALESCE(s.nama_staf, 'Sistem') AS pelaku
    FROM riwayat_baris rb LEFT JOIN staf s ON s.id_staf = rb.id_staf
UNION ALL
SELECT 'PARCEL', rp.id_parcel::text, rp.status_lama, rp.status_baru,
       rp.waktu, COALESCE(s.nama_staf, 'Sistem')
    FROM riwayat_parcel rp LEFT JOIN staf s ON s.id_staf = rp.id_staf
UNION ALL
SELECT 'BATCH', rb.id_batch::text, rb.status_lama, rb.status_baru,
       rb.waktu, COALESCE(s.nama_staf, 'Sistem')
    FROM riwayat_batch rb LEFT JOIN staf s ON s.id_staf = rb.id_staf
    ORDER BY waktu DESC;

-- MO.33

SELECT 'CS' AS peran, 'Terbitkan QRIS pelunasan' AS tugas, COUNT(*) AS antrian
    FROM parcel WHERE status = 'COMPLETE'
UNION ALL
SELECT 'CS', 'Catat kode SPX Shopee', COUNT(*)
    FROM parcel WHERE status = 'SETTLED'
UNION ALL
SELECT 'CS', 'Kirim refund ke client', COUNT(*)
    FROM refund WHERE waktu_ke_client IS NULL
UNION ALL
SELECT 'Procurement', 'Cek stok dan masukkan ke batch', COUNT(*)
    FROM baris_pesanan WHERE status = 'SIAP_CO'
UNION ALL
SELECT 'Procurement', 'Tindak lanjut barang hilang', COUNT(*)
    FROM baris_pesanan WHERE status = 'MISSING'
UNION ALL
SELECT 'PD', 'Kemas parcel', COUNT(*)
    FROM parcel WHERE status = 'CODE_ISSUED'
UNION ALL
SELECT 'PD', 'Serahkan parcel ke kurir', COUNT(*)
    FROM parcel WHERE status = 'PACKED';

-- MO.34

SELECT CASE WHEN GROUPING(v.nama) = 0 THEN 'Produk'
            WHEN GROUPING(r.nama_rarity) = 0 THEN 'Rarity'
            WHEN GROUPING(d.nama_toko) = 0 THEN 'Distributor'
            ELSE 'Shipper' END AS dimensi,
       COALESCE(v.nama, r.nama_rarity, d.nama_toko, sh.nama_shipper) AS nilai,
       SUM(bp.jumlah) AS unit_terjual,
       SUM(bp.harga_jual * bp.jumlah) AS penjualan,
       SUM(bp.harga_jual * bp.jumlah - bp.modal_shipper * bp.jumlah - bp.perkiraan_biaya_berat) AS profit
    FROM baris_pesanan bp
    JOIN penawaran p ON p.id_penawaran = bp.id_penawaran
    JOIN v_produk v ON v.id_produk = COALESCE(p.id_kartu_individual, p.id_set_kartu)
    JOIN rarity r ON r.id_rarity = v.id_rarity
    JOIN distributor d ON d.id_distributor = p.id_distributor
    JOIN pesanan ps ON ps.id_pesanan = bp.id_pesanan
    JOIN parcel pc ON pc.id_parcel = ps.id_parcel
    JOIN sesi_jastip s ON s.id_sesi = pc.id_sesi
    JOIN shipper sh ON sh.id_shipper = s.id_shipper
    WHERE bp.status NOT IN ('MENUNGGU_DP','KEDALUWARSA','REFUNDED','STOK_HABIS')
    GROUP BY GROUPING SETS ((v.nama), (r.nama_rarity), (d.nama_toko), (sh.nama_shipper))
    ORDER BY dimensi, profit DESC;

-- MO.35

SELECT sh.nama_shipper, s.nama_sesi,
       SUM(bp.modal_shipper * bp.jumlah + bp.perkiraan_biaya_berat) AS kewajiban_rp
    FROM baris_pesanan bp
    JOIN batch_pengadaan b ON b.id_batch = bp.id_batch
    JOIN sesi_jastip s ON s.id_sesi = b.id_sesi
    JOIN shipper sh ON sh.id_shipper = s.id_shipper
    WHERE b.status <> 'COLLECTING'
      AND bp.status <> 'REFUNDED'
    GROUP BY sh.nama_shipper, s.nama_sesi, s.waktu_mulai
    ORDER BY s.waktu_mulai;

-- MO.36

WITH tagihan AS (
    SELECT ps.id_parcel, SUM(bp.harga_jual * bp.jumlah) AS total
    FROM baris_pesanan bp JOIN pesanan ps ON ps.id_pesanan = bp.id_pesanan
    WHERE bp.status NOT IN ('KEDALUWARSA','REFUNDED','STOK_HABIS')
    GROUP BY ps.id_parcel),
dp AS (
    SELECT ps.id_parcel, SUM(d.nominal) AS dibayar
    FROM pembayaran_dp d JOIN pesanan ps ON ps.id_pesanan = d.id_pesanan
    WHERE d.status_qris = 'PAID' GROUP BY ps.id_parcel),
rf AS (
    SELECT ps.id_parcel, SUM(r.nominal) AS kembali
    FROM refund r JOIN pesanan ps ON ps.id_pesanan = r.id_pesanan
    GROUP BY ps.id_parcel),
lunas AS (
    SELECT id_parcel, SUM(nominal) AS dibayar
    FROM pembayaran_pelunasan WHERE status_qris = 'PAID' GROUP BY id_parcel)
SELECT s.nama_sesi,
       SUM(COALESCE(d.dibayar, 0) - COALESCE(rf.kembali, 0)) AS dp_terkumpul,
       SUM(COALESCE(l.dibayar, 0)) AS pelunasan_terbayar,
       COUNT(*) FILTER (WHERE p.status IN ('OPEN','INCOMPLETE','COMPLETE')) AS parcel_belum_lunas,
       SUM(t.total - (COALESCE(d.dibayar, 0) - COALESCE(rf.kembali, 0)) - COALESCE(l.dibayar, 0))
           FILTER (WHERE p.status = 'COMPLETE') AS pelunasan_tertunggak
    FROM parcel p
    JOIN sesi_jastip s ON s.id_sesi = p.id_sesi
    JOIN tagihan t ON t.id_parcel = p.id_parcel
    LEFT JOIN dp d ON d.id_parcel = p.id_parcel
    LEFT JOIN rf ON rf.id_parcel = p.id_parcel
    LEFT JOIN lunas l ON l.id_parcel = p.id_parcel
    GROUP BY s.nama_sesi, s.waktu_mulai
    ORDER BY s.waktu_mulai;

-- MO.37

SELECT pc.id_parcel, c.nama_lengkap, s.nama_sesi AS periode, pc.status,
       SUM(bp.harga_jual * bp.jumlah) AS pendapatan,
       SUM(bp.modal_shipper * bp.jumlah + bp.perkiraan_biaya_berat) AS modal_dan_biaya_berat,
       COALESCE(pc.biaya_kemasan, 0) AS biaya_kemasan,
       SUM(bp.harga_jual * bp.jumlah)
           - SUM(bp.modal_shipper * bp.jumlah + bp.perkiraan_biaya_berat)
           - COALESCE(pc.biaya_kemasan, 0) AS laba_bersih
    FROM parcel pc
    JOIN client c ON c.id_client = pc.id_client
    JOIN sesi_jastip s ON s.id_sesi = pc.id_sesi
    JOIN pesanan ps ON ps.id_parcel = pc.id_parcel
    JOIN baris_pesanan bp ON bp.id_pesanan = ps.id_pesanan
    WHERE pc.status IN ('PACKED','HANDED_OVER','RECEIVED')
      AND bp.status NOT IN ('KEDALUWARSA','REFUNDED','STOK_HABIS')
    GROUP BY pc.id_parcel, c.nama_lengkap, s.nama_sesi, pc.status, pc.biaya_kemasan
    ORDER BY pc.id_parcel;

-- MO.38

SELECT pk.id_pembelian, pk.ukuran, pk.jumlah,
       COUNT(p.id_parcel) AS terpakai,
       pk.jumlah - COUNT(p.id_parcel) AS sisa,
       ROUND(pk.total_biaya / pk.jumlah) AS unit_cost,
       ROUND(pk.total_biaya / pk.jumlah) * (pk.jumlah - COUNT(p.id_parcel)) AS nilai_sisa
    FROM pembelian_kemasan pk
    LEFT JOIN parcel p ON p.id_pembelian = pk.id_pembelian
    GROUP BY pk.id_pembelian, pk.ukuran, pk.jumlah, pk.total_biaya
    ORDER BY pk.tanggal_beli, pk.id_pembelian;

-- MO.39

SELECT ls.waktu, ls.jenis, pl.nama_staf AS pelapor, pn.nama_staf AS penerima, ls.isi
    FROM laporan_staf ls
    JOIN staf pl ON pl.id_staf = ls.id_pelapor
    JOIN staf pn ON pn.id_staf = ls.id_penerima
    ORDER BY ls.waktu DESC;

-- MO.40

SELECT bp.id_pesanan, bp.no_baris, bp.status, c.nama_lengkap, r.nominal AS nominal_refund
    FROM baris_pesanan bp
    JOIN pesanan ps ON ps.id_pesanan = bp.id_pesanan
    JOIN parcel pc ON pc.id_parcel = ps.id_parcel
    JOIN client c ON c.id_client = pc.id_client
    LEFT JOIN refund r ON r.id_pesanan = bp.id_pesanan AND r.no_baris = bp.no_baris
    WHERE bp.status IN ('STOK_HABIS','MISSING','REFUNDED','EXCHANGED')
    ORDER BY bp.status, bp.id_pesanan, bp.no_baris;
