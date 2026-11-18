-- BR-01: produk wajib punya minimal satu penawaran aktif (dicek saat COMMIT)

CREATE OR REPLACE FUNCTION fn_cek_penawaran_aktif(p_id_produk INT)
RETURNS void
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM v_produk WHERE id_produk = p_id_produk) THEN
        RETURN;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM penawaran
        WHERE ketersediaan = true
          AND (id_kartu_individual = p_id_produk OR id_set_kartu = p_id_produk)
    ) THEN
        RAISE EXCEPTION 'BR-01: produk % tidak memiliki penawaran aktif', p_id_produk;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION trg_produk_br01()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    PERFORM fn_cek_penawaran_aktif(NEW.id_produk);
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION trg_penawaran_br01()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    PERFORM fn_cek_penawaran_aktif(COALESCE(OLD.id_kartu_individual, OLD.id_set_kartu));
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER br01_kartu_individual
    AFTER INSERT ON kartu_individual
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION trg_produk_br01();

CREATE CONSTRAINT TRIGGER br01_set_kartu
    AFTER INSERT ON set_kartu
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION trg_produk_br01();

CREATE CONSTRAINT TRIGGER br01_penawaran
    AFTER UPDATE OR DELETE ON penawaran
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION trg_penawaran_br01();

-- BR-12: pesanan hanya dapat dibuat pada sesi aktif

CREATE OR REPLACE FUNCTION trg_pesanan_br12()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_sesi sesi_jastip%ROWTYPE;
BEGIN
    SELECT s.* INTO v_sesi
    FROM parcel p JOIN sesi_jastip s ON s.id_sesi = p.id_sesi
    WHERE p.id_parcel = NEW.id_parcel;

    IF NEW.waktu_pesan < v_sesi.waktu_mulai
       OR NEW.waktu_pesan > COALESCE(v_sesi.waktu_tutup, 'infinity'::timestamptz)
       OR (v_sesi.status = 'ENDED' AND v_sesi.waktu_tutup IS NULL) THEN
        RAISE EXCEPTION 'BR-12: sesi "%" tidak aktif pada %', v_sesi.nama_sesi, NEW.waktu_pesan;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER br12_pesanan
    BEFORE INSERT OR UPDATE OF id_parcel, waktu_pesan ON pesanan
    FOR EACH ROW EXECUTE FUNCTION trg_pesanan_br12();

-- BR-22: nominal DP tepat 50% dari total harga pesanan (dicek saat COMMIT)

CREATE OR REPLACE FUNCTION fn_cek_dp_50(p_id_pesanan INT)
RETURNS void
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_nominal NUMERIC;
    v_total   NUMERIC;
BEGIN
    SELECT nominal INTO v_nominal FROM pembayaran_dp WHERE id_pesanan = p_id_pesanan;
    IF v_nominal IS NULL THEN
        RETURN;
    END IF;
    SELECT COALESCE(SUM(harga_jual * jumlah), 0) INTO v_total
    FROM baris_pesanan WHERE id_pesanan = p_id_pesanan;
    IF v_nominal <> ROUND(v_total / 2) THEN
        RAISE EXCEPTION 'BR-22: DP pesanan % = %, seharusnya % (50%% dari %)',
            p_id_pesanan, v_nominal, ROUND(v_total / 2), v_total;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION trg_dp_br22()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF TG_TABLE_NAME = 'pembayaran_dp' THEN
        PERFORM fn_cek_dp_50(NEW.id_pesanan);
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM fn_cek_dp_50(OLD.id_pesanan);
    ELSE
        PERFORM fn_cek_dp_50(NEW.id_pesanan);
        IF TG_OP = 'UPDATE' AND OLD.id_pesanan <> NEW.id_pesanan THEN
            PERFORM fn_cek_dp_50(OLD.id_pesanan);
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER br22_pembayaran_dp
    AFTER INSERT OR UPDATE OF nominal, id_pesanan ON pembayaran_dp
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION trg_dp_br22();

CREATE CONSTRAINT TRIGGER br22_baris_pesanan
    AFTER INSERT OR UPDATE OF harga_jual, jumlah, id_pesanan OR DELETE ON baris_pesanan
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION trg_dp_br22();

-- Status turunan: dihitung lewat view, tidak disimpan sebagai kolom

CREATE OR REPLACE VIEW v_status_pesanan WITH (security_invoker = true) AS
WITH tahap AS (
    SELECT id_pesanan, status,
           array_position(ARRAY['MENUNGGU_DP','SIAP_CO','SUDAH_CO','DI_GUDANG_CN','DI_GUDANG_ID',
                                'MISSING','ARRIVED','EXCHANGED']::varchar[], status) AS urutan
    FROM baris_pesanan)
SELECT ps.id_pesanan, ps.id_parcel,
       COUNT(t.status) AS jumlah_baris,
       COUNT(t.urutan) AS baris_aktif,
       CASE
           WHEN COUNT(t.urutan) = 0 THEN 'BATAL'
           WHEN MIN(t.urutan) = 1 THEN 'MENUNGGU_DP'
           WHEN MIN(t.urutan) = 2 THEN 'SIAP_CO'
           WHEN MIN(t.urutan) IN (3, 4, 5) THEN 'DALAM_PENGIRIMAN'
           WHEN MIN(t.urutan) = 6 THEN 'ADA_BARANG_HILANG'
           ELSE 'TIBA'
       END AS status_pesanan
FROM pesanan ps
JOIN tahap t ON t.id_pesanan = ps.id_pesanan
GROUP BY ps.id_pesanan, ps.id_parcel;

CREATE OR REPLACE VIEW v_cakupan_bayar WITH (security_invoker = true) AS
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
SELECT p.id_parcel, p.status,
       COALESCE(t.total, 0) AS total,
       COALESCE(d.dibayar, 0) - COALESCE(rf.kembali, 0) AS dp_bersih,
       COALESCE(l.dibayar, 0) AS pelunasan,
       COALESCE(t.total, 0) - (COALESCE(d.dibayar, 0) - COALESCE(rf.kembali, 0)) - COALESCE(l.dibayar, 0) AS sisa,
       CASE
           WHEN COALESCE(t.total, 0) = 0 THEN 'TIDAK_ADA_TAGIHAN'
           WHEN COALESCE(d.dibayar, 0) = 0 THEN 'BELUM_DP'
           WHEN COALESCE(t.total, 0) - (COALESCE(d.dibayar, 0) - COALESCE(rf.kembali, 0)) - COALESCE(l.dibayar, 0) > 0 THEN 'DP'
           ELSE 'LUNAS'
       END AS cakupan_bayar
FROM parcel p
LEFT JOIN tagihan t ON t.id_parcel = p.id_parcel
LEFT JOIN dp d ON d.id_parcel = p.id_parcel
LEFT JOIN rf ON rf.id_parcel = p.id_parcel
LEFT JOIN lunas l ON l.id_parcel = p.id_parcel;

CREATE OR REPLACE VIEW v_laba_parcel WITH (security_invoker = true) AS
SELECT pc.id_parcel, pc.id_client, pc.id_sesi, pc.status,
       SUM(bp.harga_jual * bp.jumlah) AS pendapatan,
       SUM(bp.modal_shipper * bp.jumlah + bp.perkiraan_biaya_berat) AS modal_dan_biaya_berat,
       COALESCE(pc.biaya_kemasan, 0) AS biaya_kemasan,
       SUM(bp.harga_jual * bp.jumlah)
           - SUM(bp.modal_shipper * bp.jumlah + bp.perkiraan_biaya_berat)
           - COALESCE(pc.biaya_kemasan, 0) AS laba_bersih
FROM parcel pc
JOIN pesanan ps ON ps.id_parcel = pc.id_parcel
JOIN baris_pesanan bp ON bp.id_pesanan = ps.id_pesanan
WHERE bp.status NOT IN ('KEDALUWARSA','REFUNDED','STOK_HABIS')
GROUP BY pc.id_parcel, pc.id_client, pc.id_sesi, pc.status, pc.biaya_kemasan;
