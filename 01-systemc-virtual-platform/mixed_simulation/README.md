# Mešana SystemC/VHDL simulacija

Ovaj folder sadrži fajlove potrebne za pokretanje mešane SystemC/VHDL simulacije Canny hardverskog bloka.

Cilj simulacije je povezivanje SystemC virtuelne platforme sa VHDL implementacijom IP bloka i provera dobijenog izlaza u odnosu na referentni izlaz iz SystemC modela.

## Sadržaj foldera

- `main.cpp` - glavni fajl SystemC simulacije
- `cpu.cpp`, `cpu.hpp` - model procesora koji učitava sliku, pokreće IP blok i proverava rezultat
- `interconnect.cpp`, `interconnect.hpp` - model interkonekcije
- `bram.cpp`, `bram.hpp` - model memorije
- `hard.vhd` - VHDL implementacija Canny hardverskog bloka
- `hard_wrap.hpp` - SystemC omotač za VHDL IP blok
- `hard_tlm_bridge.cpp`, `hard_tlm_bridge.hpp` - most između SystemC platforme i VHDL IP bloka
- `defines.hpp` - zajedničke konstante i adrese
- `grayscale_full.txt` - ulazna grayscale slika u tekstualnom formatu
- `final_edge_full.txt` - referentni izlaz dobijen iz SystemC modela
- `Makefile` - fajl za pokretanje simulacije pomoću Cadence Xcelium alata

## Pokretanje simulacije

Pre pokretanja simulacije potrebno je učitati Cadence okruženje:

```bash
source /cad/cds_util/bin/amsgo
```

Zatim se iz foldera `mixed_simulation` pokreće komanda:

```bash
make
```

Kada se otvori Xcelium/SimVision okruženje, u konzoli se pokreće simulacija komandom:

```tcl
run -all
```

## Ulaz i izlaz simulacije

Ulazni fajl simulacije je:

```text
grayscale_full.txt
```

Referentni izlaz iz SystemC modela je:

```text
final_edge_full.txt
```

Tokom simulacije generiše se fajl:

```text
mixed_edge_output.txt
```

Ovaj fajl predstavlja izlaznu edge sliku dobijenu iz VHDL IP bloka u okviru mešane simulacije.

Na kraju simulacije ispisuje se broj poklapanja i nepoklapanja u odnosu na referentni fajl `final_edge_full.txt`.
