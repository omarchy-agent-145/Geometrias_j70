# Rig geometry (mástil + estay) para posicionar mayor y foque

## Por qué existe este documento
Las **reglas de velas** (J/70 Class Rules, Sección G) controlan dimensiones del paño, pero **no fijan** de manera suficiente la geometría del aparejo (posición relativa mástil–estay) necesaria para colocar ambas velas en un mismo sistema de coordenadas para CFD.

Por eso el generador define un bloque `rig_params` (inputs del pipeline de geometría) que se documenta y versiona.

## Fuentes
Valores típicos de triángulo de proa (I, J) se pueden tomar de especificaciones públicas del modelo.

Ejemplo de referencia (J/Boats — J/70 technical specifications):
- https://jboats.com/j70-tech-specs

En esa tabla aparecen (métrico):
- `I = 8.159 m`
- `J = 2.34 m`
- (también reporta `P = 7.97 m`, `E = 2.88 m`)

> Nota: estos valores se usan como **defaults** del aparejo. El proyecto debe permitir sobre-escribirlos en config.

## Modelo geométrico mínimo (boat frame)
Definimos un modelo de rig simplificado por dos líneas:

### Mástil
- `mast_tack_point = (x_mast_base, z_mast_base)`
- `mast_head_point = (x_mast_head, z_mast_head)`

MVP: mástil vertical en x=0, con base en el origen:
- `mast_tack_point = (0, 0)`
- `mast_head_point = (0, mast_len)`

### Estay de proa (forestay/headstay)
- `forestay_tack_point = (x_f_tack, z_f_tack)`
- `forestay_head_point = (x_f_head, z_f_head)`

MVP usando (I, J):
- `forestay_tack_point = (J, 0)`
- `forestay_head_point = (0, I)`

Con esto el ángulo del estay respecto al mástil queda determinado por:
- `alpha = atan(J / I)`

## Cómo se aplican a las velas
- La **mayor** se genera en su `sail frame` con luff vertical y luego se mapea a lo largo de la línea del mástil.
- El **foque** se genera en su `sail frame` con luff vertical y luego se mapea a lo largo de la línea del estay.

Esto desacopla:
- medición ERS (local, consistente), de
- posicionamiento para CFD (global).

## Parámetros extra recomendados (futuro)
- `mast_rake_deg` (si queremos que el mástil no sea vertical en boat frame)
- `gooseneck_height` (altura real del pujamen/puño de amura de mayor)
- offsets laterales (y) si modelamos separación lateral de velas respecto al plano medio
