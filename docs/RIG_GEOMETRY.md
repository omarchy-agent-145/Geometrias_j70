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
Ver convención de ejes en `docs/COORDINATES.md`.

Definimos un modelo de rig simplificado por dos líneas:

### Mástil
Inputs mínimos:
- `mast_base_point = (x0, y0, z0)`
- `mast_len`
- `mast_rake_deg` (**positivo hacia popa**, es decir inclinación hacia **-x**)

Puntos derivados:
- `mast_tack_point = mast_base_point`
- `mast_head_point = mast_base_point + mast_len * dir_mast`

con (boat frame; ver `docs/COORDINATES.md`):
- `dir_mast = (-sin(rake), 0, cos(rake))` usando `rake = mast_rake_deg * π/180`.

MVP por defecto:
- `mast_base_point = (0,0,0)`
- `mast_rake_deg = 0`

### Estay de proa (forestay/headstay)
Inputs mínimos:
- `I` (altura del punto de amantillo/estay sobre el mástil, según spec)
- `J` (avance a proa desde la base del mástil al punto de amura del foque, según spec)

Puntos (MVP):
- `forestay_tack_point = (J, 0, 0)`
- `forestay_head_point = mast_base_point + I * dir_mast`  (importante: con rake aplicado)

Con esto el ángulo del estay se deriva geométricamente.

## Cómo se aplican a las velas
- La **mayor** se genera en su `sail frame` con luff vertical y luego se mapea a lo largo de la línea del mástil.
- El **foque** se genera en su `sail frame` con luff vertical y luego se mapea a lo largo de la línea del estay.

Esto desacopla:
- medición ERS (local, consistente), de
- posicionamiento para CFD (global).

## Parámetros extra recomendados (futuro)
- `mast_bend_x(z)` (curvatura del eje del mástil) como función/coeficientes; útil para modelar trim (backstay) y su efecto en la mayor.
- `luff_curve` del paño (curvatura del grátil en el planform) si se quiere aproximar construcción de vela.
- `gooseneck_height` (altura real del pujamen/puño de amura de mayor)
- offsets laterales (y) si modelamos separación lateral de velas respecto al plano medio
