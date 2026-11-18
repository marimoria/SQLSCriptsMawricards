-- 05_queries.sql : satu query per mission objective. Jalankan SATU query sekali jalan
-- (blok-seleksi lalu Run) agar hasilnya bisa di-screenshot.

-- Q01 | MO-15, MO-16 : cari kartu menurut rarity, seri, dan karakter (contoh: semua kartu SGR)
SELECT k.id_produk, k.nama, r.nama_rarity, s.nama_seri, c.nama_karakter, k.harga_jual
FROM kartu_individual k
JOIN rarity   r ON r.id_rarity   = k.id_rarity
JOIN seri     s ON s.id_seri     = k.id_seri
JOIN karakter c ON c.id_karakter = k.id_karakter
WHERE r.nama_rarity = 'SGR'
ORDER BY k.nama;

-- Q02 | MO-17, MO-26 : penawaran tersedia termurah per kartu satuan (dasar harga situs, TR-23)
SELECT DISTINCT ON (k.id_produk)
       k.id_produk, k.nama, d.nama_toko, p.harga_rmb
FROM kartu_individual k
JOIN penawaran   p ON p.id_kartu_individual = k.id_produk
JOIN distributor d ON d.id_distributor = p.id_distributor
WHERE p.ketersediaan = true
ORDER BY k.id_produk, p.harga_rmb ASC;

-- Q03 | MO-26 : produk dengan hanya satu penawaran aktif (risiko pasokan)
SELECT 'KARTU' AS jenis, k.id_produk, k.nama, COUNT(*) AS penawaran_aktif
FROM kartu_individual k
JOIN penawaran p ON p.id_kartu_individual = k.id_produk AND p.ketersediaan = true
GROUP BY k.id_produk, k.nama
HAVING COUNT(*) = 1
UNION ALL
SELECT 'SET', s.id_produk, s.nama, COUNT(*)
FROM set_kartu s
JOIN penawaran p ON p.id_set_kartu = s.id_produk AND p.ketersediaan = true
GROUP BY s.id_produk, s.nama
HAVING COUNT(*) = 1
ORDER BY jenis, id_produk;

-- Q04 | MO-03, BR-01 : validasi produk tanpa penawaran aktif (hasil yang benar: 0 baris)
SELECT v.id_produk, v.nama
FROM v_produk v
WHERE NOT EXISTS (
  SELECT 1 FROM penawaran p
  WHERE p.ketersediaan = true
    AND (p.id_kartu_individual = v.id_produk OR p.id_set_kartu = v.id_produk));

-- Q05 | MO-20, MO-23 : parcel setiap client beserta sesi dan statusnya
SELECT c.nama_lengkap, c.username_tiktok, s.nama_sesi, p.id_parcel, p.status
FROM parcel p
JOIN client c      ON c.id_client = p.id_client
JOIN sesi_jastip s ON s.id_sesi   = p.id_sesi
ORDER BY s.waktu_mulai DESC, c.nama_lengkap;

-- Q06 | MO-28 : batch COLLECTING beserta progres total harga dasar terhadap ambang (TR-24)
WITH ambang AS (
  SELECT nilai FROM parameter_berversi
  WHERE nama_parameter = 'AMBANG_BATCH'
  ORDER BY berlaku_mulai DESC LIMIT 1)
SELECT b.id_batch,
       SUM(bp.harga_dasar_rmb * bp.jumlah) AS total_rmb,
       a.nilai AS ambang_rmb
FROM batch_pengadaan b
JOIN baris_pesanan bp ON bp.id_batch = b.id_batch
CROSS JOIN ambang a
WHERE b.status = 'COLLECTING'
GROUP BY b.id_batch, a.nilai
HAVING SUM(bp.harga_dasar_rmb * bp.jumlah) < a.nilai;

-- Q07 | MO-31, MO-36 : total tagihan, DP bersih, pelunasan, dan sisa per parcel
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
       t.total - (COALESCE(d.dibayar, 0) - COALESCE(rf.kembali, 0))
               - COALESCE(l.dibayar, 0) AS sisa
FROM parcel p
JOIN tagihan t ON t.id_parcel = p.id_parcel
LEFT JOIN dp d    ON d.id_parcel  = p.id_parcel
LEFT JOIN rf      ON rf.id_parcel = p.id_parcel
LEFT JOIN lunas l ON l.id_parcel  = p.id_parcel
ORDER BY p.id_parcel;

-- Q08 | MO-25 : status pembayaran QRIS (DP dan pelunasan)
SELECT 'DP' AS jenis, status_qris, COUNT(*) AS jumlah, SUM(nominal) AS total_nominal
FROM pembayaran_dp GROUP BY status_qris
UNION ALL
SELECT 'PELUNASAN', status_qris, COUNT(*), SUM(nominal)
FROM pembayaran_pelunasan GROUP BY status_qris
ORDER BY jenis, status_qris;

-- Q09 | MO-29, MO-38 : pemakaian dan sisa stok kemasan beserta unit cost dan nilai sisa
SELECT pk.id_pembelian, pk.ukuran, pk.jumlah,
       COUNT(p.id_parcel) AS terpakai,
       pk.jumlah - COUNT(p.id_parcel) AS sisa,
       ROUND(pk.total_biaya / pk.jumlah) AS unit_cost,
       ROUND(pk.total_biaya / pk.jumlah) * (pk.jumlah - COUNT(p.id_parcel)) AS nilai_sisa
FROM pembelian_kemasan pk
LEFT JOIN parcel p ON p.id_pembelian = pk.id_pembelian
GROUP BY pk.id_pembelian, pk.ukuran, pk.jumlah, pk.total_biaya
ORDER BY pk.tanggal_beli, pk.id_pembelian;

-- Q10 | MO-40 : baris stok habis, hilang, direfund, atau ditukar beserta nominal refund
SELECT bp.id_pesanan, bp.no_baris, bp.status, c.nama_lengkap, r.nominal AS nominal_refund
FROM baris_pesanan bp
JOIN pesanan ps ON ps.id_pesanan = bp.id_pesanan
JOIN parcel  pc ON pc.id_parcel  = ps.id_parcel
JOIN client  c  ON c.id_client   = pc.id_client
LEFT JOIN refund r ON r.id_pesanan = bp.id_pesanan AND r.no_baris = bp.no_baris
WHERE bp.status IN ('STOK_HABIS','MISSING','REFUNDED','EXCHANGED')
ORDER BY bp.status, bp.id_pesanan, bp.no_baris;

-- Q11 | MO-34, MO-37 : laba per parcel yang sudah dikemas (modal, biaya berat, kemasan)
SELECT pc.id_parcel, c.nama_lengkap, pc.status,
       SUM(bp.harga_jual * bp.jumlah)                                AS pendapatan,
       SUM(bp.modal_shipper * bp.jumlah + bp.perkiraan_biaya_berat)  AS modal_dan_biaya_berat,
       COALESCE(pc.biaya_kemasan, 0)                                 AS biaya_kemasan,
       SUM(bp.harga_jual * bp.jumlah)
         - SUM(bp.modal_shipper * bp.jumlah + bp.perkiraan_biaya_berat)
         - COALESCE(pc.biaya_kemasan, 0)                             AS laba_bersih
FROM parcel pc
JOIN client c         ON c.id_client   = pc.id_client
JOIN pesanan ps       ON ps.id_parcel  = pc.id_parcel
JOIN baris_pesanan bp ON bp.id_pesanan = ps.id_pesanan
WHERE pc.status IN ('PACKED','HANDED_OVER','RECEIVED')
  AND bp.status NOT IN ('KEDALUWARSA','REFUNDED','STOK_HABIS')
GROUP BY pc.id_parcel, c.nama_lengkap, pc.status, pc.biaya_kemasan
ORDER BY pc.id_parcel;

-- Q12 | MO-35 : kewajiban bayar ke shipper per sesi (batch yang sudah dipesan)
SELECT sh.nama_shipper, s.nama_sesi,
       SUM(bp.modal_shipper * bp.jumlah + bp.perkiraan_biaya_berat) AS kewajiban_rp
FROM baris_pesanan bp
JOIN batch_pengadaan b ON b.id_batch   = bp.id_batch
JOIN sesi_jastip s     ON s.id_sesi    = b.id_sesi
JOIN shipper sh        ON sh.id_shipper = s.id_shipper
WHERE b.status <> 'COLLECTING'
  AND bp.status <> 'REFUNDED'
GROUP BY sh.nama_shipper, s.nama_sesi, s.waktu_mulai
ORDER BY s.waktu_mulai;

-- Q13 | MO-32 : riwayat perubahan status baris beserta pelaku dan waktunya
SELECT rb.id_pesanan, rb.no_baris, rb.status_lama, rb.status_baru, rb.waktu,
       COALESCE(s.nama_staf, 'Sistem') AS pelaku
FROM riwayat_baris rb
LEFT JOIN staf s ON s.id_staf = rb.id_staf
ORDER BY rb.waktu DESC;
