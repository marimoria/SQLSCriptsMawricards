-- Sequence bersama untuk kartu_individual dan set_kartu (subclass Produk)
CREATE SEQUENCE seq_produk;

-- 1. Tabel referensi

CREATE TABLE rarity (
    id_rarity    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_rarity  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE seri (
    id_seri    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_seri  VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE karakter (
    id_karakter    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_karakter  VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE distributor (
    id_distributor  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_toko       VARCHAR(150) NOT NULL UNIQUE,
    platform        VARCHAR(20)  NOT NULL
                    CHECK (platform IN ('PINDUODUO','XIANYU')),
    tautan_toko     TEXT
);

CREATE TABLE shipper (
    id_shipper    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_shipper  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE staf (
    id_staf       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    auth_user_id  UUID UNIQUE REFERENCES auth.users(id) ON DELETE RESTRICT,
    nama_staf     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    peran         VARCHAR(15)  NOT NULL
                  CHECK (peran IN ('Owner','CS','Procurement','PD'))
);

CREATE TABLE client (
    id_client        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    auth_user_id     UUID UNIQUE REFERENCES auth.users(id) ON DELETE RESTRICT,
    nama_lengkap     VARCHAR(100) NOT NULL,
    username_tiktok  VARCHAR(50)  NOT NULL UNIQUE,
    no_whatsapp      VARCHAR(20)  NOT NULL,
    email            VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE pembelian_kemasan (
    id_pembelian  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tanggal_beli  DATE NOT NULL DEFAULT CURRENT_DATE,
    sumber        VARCHAR(100) NOT NULL,
    ukuran        VARCHAR(10)  NOT NULL CHECK (ukuran IN ('KECIL','BESAR')),
    jumlah        INT NOT NULL CHECK (jumlah > 0),
    total_biaya   NUMERIC(12,0) NOT NULL CHECK (total_biaya >= 0),
    dicatat_oleh  INT NOT NULL REFERENCES staf(id_staf) ON DELETE RESTRICT
);

-- 2. Rubrik tarif dan parameter berversi

CREATE TABLE rubrik_tarif (
    id_rubrik       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_shipper      INT NOT NULL REFERENCES shipper(id_shipper) ON DELETE RESTRICT,
    berlaku_mulai   DATE NOT NULL,
    berlaku_sampai  DATE CHECK (berlaku_sampai > berlaku_mulai)
);

CREATE TABLE tingkat_tarif (
    id_rubrik      INT NOT NULL REFERENCES rubrik_tarif(id_rubrik) ON DELETE CASCADE,
    no_tingkat     INT NOT NULL CHECK (no_tingkat > 0),
    harga_min_rmb  NUMERIC(10,2) NOT NULL CHECK (harga_min_rmb >= 0),
    harga_maks_rmb NUMERIC(10,2) CHECK (harga_maks_rmb > harga_min_rmb),
    persen_markup  NUMERIC(5,2)  NOT NULL CHECK (persen_markup BETWEEN 0 AND 100),
    PRIMARY KEY (id_rubrik, no_tingkat)
);

CREATE TABLE tingkat_berat (
    id_rubrik        INT NOT NULL REFERENCES rubrik_tarif(id_rubrik) ON DELETE CASCADE,
    no_tingkat       INT NOT NULL CHECK (no_tingkat > 0),
    berat_min_gram   INT NOT NULL CHECK (berat_min_gram >= 0),
    berat_maks_gram  INT CHECK (berat_maks_gram > berat_min_gram),
    tarif_per_gram   NUMERIC(10,2) NOT NULL CHECK (tarif_per_gram >= 0),
    PRIMARY KEY (id_rubrik, no_tingkat)
);

CREATE TABLE parameter_berversi (
    id_parameter    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_parameter  VARCHAR(40) NOT NULL
                    CHECK (nama_parameter IN ('KURS','BERAT_KARTU','BERAT_TOPLOADER',
                           'BERAT_WADAH_KECIL','AMBANG_BATCH','HARGA_LISTING_SHOPEE',
                           'BATAS_KEMASAN_KECIL','ESTIMASI_KEMASAN_BARIS')),
    nilai           NUMERIC(14,4) NOT NULL,
    id_shipper      INT REFERENCES shipper(id_shipper) ON DELETE RESTRICT,
    berlaku_mulai   TIMESTAMPTZ NOT NULL DEFAULT now(),
    ditetapkan_oleh INT NOT NULL REFERENCES staf(id_staf) ON DELETE RESTRICT
);

-- 3. Produk (subclass Produk) dan penawaran

CREATE TABLE kartu_individual (
    id_produk       INT PRIMARY KEY DEFAULT nextval('seq_produk'),
    nama            VARCHAR(150) NOT NULL,
    harga_jual      NUMERIC(12,0) NOT NULL CHECK (harga_jual > 0),
    url_gambar      TEXT CHECK (url_gambar ~ '^https?://'),
    id_rarity       INT NOT NULL REFERENCES rarity(id_rarity) ON DELETE RESTRICT,
    id_seri         INT NOT NULL REFERENCES seri(id_seri) ON DELETE RESTRICT,
    id_karakter     INT NOT NULL REFERENCES karakter(id_karakter) ON DELETE RESTRICT,
    disetujui_oleh  INT REFERENCES staf(id_staf) ON DELETE RESTRICT
);

CREATE TABLE set_kartu (
    id_produk       INT PRIMARY KEY DEFAULT nextval('seq_produk'),
    nama            VARCHAR(150) NOT NULL,
    harga_jual      NUMERIC(12,0) NOT NULL CHECK (harga_jual > 0),
    url_gambar      TEXT CHECK (url_gambar ~ '^https?://'),
    jumlah_kartu    INT NOT NULL CHECK (jumlah_kartu > 0),
    id_rarity       INT NOT NULL REFERENCES rarity(id_rarity) ON DELETE RESTRICT,
    id_seri         INT NOT NULL REFERENCES seri(id_seri) ON DELETE RESTRICT,
    disetujui_oleh  INT REFERENCES staf(id_staf) ON DELETE RESTRICT
);

CREATE TABLE berisi (
    id_set    INT NOT NULL REFERENCES set_kartu(id_produk) ON DELETE CASCADE,
    id_kartu  INT NOT NULL REFERENCES kartu_individual(id_produk) ON DELETE RESTRICT,
    PRIMARY KEY (id_set, id_kartu)
);

CREATE TABLE set_karakter (
    id_produk    INT NOT NULL REFERENCES set_kartu(id_produk) ON DELETE CASCADE,
    id_karakter  INT NOT NULL REFERENCES karakter(id_karakter) ON DELETE RESTRICT,
    PRIMARY KEY (id_produk, id_karakter)
);

CREATE TABLE penawaran (
    id_penawaran         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_kartu_individual  INT REFERENCES kartu_individual(id_produk) ON DELETE RESTRICT,
    id_set_kartu         INT REFERENCES set_kartu(id_produk) ON DELETE RESTRICT,
    id_distributor       INT NOT NULL REFERENCES distributor(id_distributor) ON DELETE RESTRICT,
    harga_rmb            NUMERIC(10,2) NOT NULL CHECK (harga_rmb > 0),
    tautan               TEXT,
    ketersediaan         BOOLEAN NOT NULL DEFAULT true,
    minimum_qty          INT NOT NULL DEFAULT 1 CHECK (minimum_qty > 0),
    CHECK (num_nonnulls(id_kartu_individual, id_set_kartu) = 1),
    UNIQUE (id_kartu_individual, id_distributor),
    UNIQUE (id_set_kartu, id_distributor)
);

-- 4. Sesi, batch, parcel, pesanan

CREATE TABLE sesi_jastip (
    id_sesi       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_sesi     VARCHAR(100) NOT NULL,
    status        VARCHAR(10) NOT NULL DEFAULT 'ACTIVE'
                  CHECK (status IN ('ACTIVE','ENDED')),
    waktu_mulai   TIMESTAMPTZ NOT NULL DEFAULT now(),
    waktu_tutup   TIMESTAMPTZ CHECK (waktu_tutup >= waktu_mulai),
    id_shipper    INT NOT NULL REFERENCES shipper(id_shipper) ON DELETE RESTRICT,
    ditutup_oleh  INT REFERENCES staf(id_staf) ON DELETE RESTRICT
);

CREATE TABLE batch_pengadaan (
    id_batch       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sesi        INT NOT NULL REFERENCES sesi_jastip(id_sesi) ON DELETE RESTRICT,
    status         VARCHAR(15) NOT NULL DEFAULT 'COLLECTING'
                   CHECK (status IN ('COLLECTING','CHECKING','ORDERED',
                                     'IN_PROGRESS','FINISHED')),
    waktu_dipesan  TIMESTAMPTZ
);

CREATE TABLE parcel (
    id_parcel      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_client      INT NOT NULL REFERENCES client(id_client) ON DELETE RESTRICT,
    id_sesi        INT NOT NULL REFERENCES sesi_jastip(id_sesi) ON DELETE RESTRICT,
    status         VARCHAR(15) NOT NULL DEFAULT 'OPEN'
                   CHECK (status IN ('OPEN','INCOMPLETE','COMPLETE','SETTLED',
                                     'CODE_ISSUED','PACKED','HANDED_OVER','RECEIVED')),
    waktu_lengkap  TIMESTAMPTZ,
    ditandai_oleh  INT REFERENCES staf(id_staf) ON DELETE RESTRICT,
    biaya_kemasan  NUMERIC(12,0) CHECK (biaya_kemasan >= 0),
    id_pembelian   INT REFERENCES pembelian_kemasan(id_pembelian) ON DELETE RESTRICT,
    UNIQUE (id_client, id_sesi)
);

CREATE TABLE pesanan (
    id_pesanan   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_parcel    INT NOT NULL REFERENCES parcel(id_parcel) ON DELETE RESTRICT,
    waktu_pesan  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE baris_pesanan (
    id_pesanan             INT NOT NULL REFERENCES pesanan(id_pesanan) ON DELETE RESTRICT,
    no_baris               INT NOT NULL CHECK (no_baris > 0),
    id_penawaran           INT NOT NULL REFERENCES penawaran(id_penawaran) ON DELETE RESTRICT,
    id_batch               INT REFERENCES batch_pengadaan(id_batch) ON DELETE RESTRICT,
    jumlah                 INT NOT NULL CHECK (jumlah > 0),
    berat_gram             INT NOT NULL CHECK (berat_gram > 0),
    harga_dasar_rmb        NUMERIC(10,2) NOT NULL CHECK (harga_dasar_rmb > 0),
    harga_jual             NUMERIC(12,0) NOT NULL CHECK (harga_jual > 0),
    modal_shipper          NUMERIC(12,0) NOT NULL CHECK (modal_shipper >= 0),
    perkiraan_biaya_berat  NUMERIC(12,0) NOT NULL DEFAULT 0 CHECK (perkiraan_biaya_berat >= 0),
    status                 VARCHAR(15) NOT NULL DEFAULT 'MENUNGGU_DP'
                           CHECK (status IN ('MENUNGGU_DP','KEDALUWARSA','SIAP_CO','STOK_HABIS',
                                             'SUDAH_CO','DI_GUDANG_CN','DI_GUDANG_ID','EXCHANGED',
                                             'MISSING','REFUNDED','ARRIVED')),
    PRIMARY KEY (id_pesanan, no_baris)
);

-- 5. Sisanya: cek stok, penukaran, pembayaran, refund, shopee, laporan, riwayat

CREATE TABLE cek_stok (
    id_pesanan  INT NOT NULL,
    no_baris    INT NOT NULL,
    no_cek      INT NOT NULL CHECK (no_cek > 0),
    tahap       VARCHAR(10) NOT NULL CHECK (tahap IN ('PRA_PESAN','PRA_BATCH')),
    hasil       VARCHAR(10) NOT NULL CHECK (hasil IN ('TERSEDIA','HABIS')),
    id_staf     INT NOT NULL REFERENCES staf(id_staf) ON DELETE RESTRICT,
    waktu_cek   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_pesanan, no_baris, no_cek),
    FOREIGN KEY (id_pesanan, no_baris)
        REFERENCES baris_pesanan(id_pesanan, no_baris) ON DELETE RESTRICT
);

CREATE TABLE penukaran (
    id_pesanan         INT NOT NULL,
    no_baris           INT NOT NULL,
    no_tukar           INT NOT NULL CHECK (no_tukar > 0),
    id_penawaran_lama  INT NOT NULL REFERENCES penawaran(id_penawaran) ON DELETE RESTRICT,
    id_penawaran_baru  INT NOT NULL REFERENCES penawaran(id_penawaran) ON DELETE RESTRICT
                       CHECK (id_penawaran_baru <> id_penawaran_lama),
    id_staf            INT NOT NULL REFERENCES staf(id_staf) ON DELETE RESTRICT,
    waktu_tukar        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_pesanan, no_baris, no_tukar),
    FOREIGN KEY (id_pesanan, no_baris)
        REFERENCES baris_pesanan(id_pesanan, no_baris) ON DELETE RESTRICT
);

CREATE TABLE pembayaran_dp (
    id_pembayaran      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nominal            NUMERIC(12,0) NOT NULL CHECK (nominal > 0),
    status_qris        VARCHAR(10) NOT NULL DEFAULT 'PENDING'
                       CHECK (status_qris IN ('PENDING','PAID','EXPIRED')),
    waktu_dibuat       TIMESTAMPTZ NOT NULL DEFAULT now(),
    waktu_kedaluwarsa  TIMESTAMPTZ NOT NULL,
    waktu_dibayar      TIMESTAMPTZ,
    id_pesanan         INT NOT NULL UNIQUE REFERENCES pesanan(id_pesanan) ON DELETE RESTRICT,
    CHECK (waktu_kedaluwarsa > waktu_dibuat)
);

CREATE TABLE pembayaran_pelunasan (
    id_pembayaran      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nominal            NUMERIC(12,0) NOT NULL CHECK (nominal > 0),
    status_qris        VARCHAR(10) NOT NULL DEFAULT 'PENDING'
                       CHECK (status_qris IN ('PENDING','PAID','EXPIRED')),
    waktu_dibuat       TIMESTAMPTZ NOT NULL DEFAULT now(),
    waktu_kedaluwarsa  TIMESTAMPTZ NOT NULL,
    waktu_dibayar      TIMESTAMPTZ,
    id_parcel          INT NOT NULL REFERENCES parcel(id_parcel) ON DELETE RESTRICT,
    diterbitkan_oleh   INT NOT NULL REFERENCES staf(id_staf) ON DELETE RESTRICT,
    CHECK (waktu_kedaluwarsa > waktu_dibuat)
);

CREATE TABLE refund (
    id_refund           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pesanan          INT NOT NULL,
    no_baris            INT NOT NULL,
    nominal             NUMERIC(12,0) NOT NULL CHECK (nominal > 0),
    alasan              VARCHAR(15) NOT NULL CHECK (alasan IN ('STOK_HABIS','BARANG_HILANG')),
    diterima_oleh       INT REFERENCES staf(id_staf) ON DELETE RESTRICT,
    waktu_dari_shipper  TIMESTAMPTZ,
    diberikan_oleh      INT REFERENCES staf(id_staf) ON DELETE RESTRICT,
    waktu_ke_client     TIMESTAMPTZ,
    UNIQUE (id_pesanan, no_baris),
    FOREIGN KEY (id_pesanan, no_baris)
        REFERENCES baris_pesanan(id_pesanan, no_baris) ON DELETE RESTRICT
);

CREATE TABLE transaksi_shopee (
    id_parcel          INT PRIMARY KEY REFERENCES parcel(id_parcel) ON DELETE RESTRICT,
    no_pesanan_shopee  VARCHAR(30) NOT NULL UNIQUE,
    kode_spx           VARCHAR(30) NOT NULL UNIQUE CHECK (kode_spx ~ '^SPX[0-9]+$'),
    nominal_listing    NUMERIC(12,0) NOT NULL DEFAULT 99 CHECK (nominal_listing >= 0),
    waktu_transaksi    TIMESTAMPTZ NOT NULL DEFAULT now(),
    dicatat_oleh       INT NOT NULL REFERENCES staf(id_staf) ON DELETE RESTRICT
);

CREATE TABLE laporan_staf (
    id_laporan   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    jenis        VARCHAR(25) NOT NULL
                 CHECK (jenis IN ('LAPORAN_CS','LAPORAN_PROCUREMENT','LAPORAN_PD')),
    isi          TEXT NOT NULL,
    waktu        TIMESTAMPTZ NOT NULL DEFAULT now(),
    id_pelapor   INT NOT NULL REFERENCES staf(id_staf) ON DELETE RESTRICT,
    id_penerima  INT NOT NULL REFERENCES staf(id_staf) ON DELETE RESTRICT
);

CREATE TABLE riwayat_baris (
    id_riwayat   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_lama  VARCHAR(15),
    status_baru  VARCHAR(15) NOT NULL,
    waktu        TIMESTAMPTZ NOT NULL DEFAULT now(),
    id_staf      INT REFERENCES staf(id_staf) ON DELETE RESTRICT,
    id_pesanan   INT NOT NULL,
    no_baris     INT NOT NULL,
    FOREIGN KEY (id_pesanan, no_baris)
        REFERENCES baris_pesanan(id_pesanan, no_baris) ON DELETE RESTRICT
);

CREATE TABLE riwayat_parcel (
    id_riwayat   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_lama  VARCHAR(15),
    status_baru  VARCHAR(15) NOT NULL,
    waktu        TIMESTAMPTZ NOT NULL DEFAULT now(),
    id_staf      INT REFERENCES staf(id_staf) ON DELETE RESTRICT,
    id_parcel    INT NOT NULL REFERENCES parcel(id_parcel) ON DELETE RESTRICT
);

CREATE TABLE riwayat_batch (
    id_riwayat   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_lama  VARCHAR(15),
    status_baru  VARCHAR(15) NOT NULL,
    waktu        TIMESTAMPTZ NOT NULL DEFAULT now(),
    id_staf      INT REFERENCES staf(id_staf) ON DELETE RESTRICT,
    id_batch     INT NOT NULL REFERENCES batch_pengadaan(id_batch) ON DELETE RESTRICT
);

-- View opsional: satu daftar produk untuk situs web (UNION ALL kedua subclass)
CREATE VIEW v_produk AS
    SELECT id_produk, 'KARTU'::text AS jenis, nama, harga_jual, url_gambar, id_rarity, id_seri
    FROM kartu_individual
    UNION ALL
    SELECT id_produk, 'SET'::text, nama, harga_jual, url_gambar, id_rarity, id_seri
    FROM set_kartu;
