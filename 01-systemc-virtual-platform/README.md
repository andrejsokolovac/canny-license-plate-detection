# SystemC projekat – Detekcija registarskih tablica

## Opis

Ovaj projekat implementira SystemC simulaciju za detekciju registarskih tablica na slici. Uključeni su moduli za CPU, memoriju (BRAM), interkonekciju i hardverski akcelerator (Canny edge).

## Struktura 

- `cpu_test` – izvršni fajl koji pokreće simulaciju 
- `data/` – folder sa ulaznim slikama 
- `vp_output/` – folder gde se čuvaju rezultati obrade 

## Zahtevi

- SystemC biblioteka (verzija 2.3 ili novija)
- OpenCV biblioteka

## Kompilacija

U korenskom direktorijumu (`y25-g08/vp`) pokrenuti:

- make clean
- make 
- ./cpu_test apsoltna_putanja_do_slike 
