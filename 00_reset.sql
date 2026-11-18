-- Kosongkan semua data dan ulang penomoran identity dan sequence, lalu jalankan ulang 03_seed.sql

TRUNCATE TABLE rarity, seri, karakter, distributor, shipper,
               staf, client, pembelian_kemasan
RESTART IDENTITY CASCADE;

ALTER SEQUENCE seq_produk RESTART WITH 1;
