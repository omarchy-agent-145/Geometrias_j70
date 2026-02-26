# Decisiones cerradas / abiertas (control de ambigüedad)

Este documento existe para que la implementación sea **única** y reproducible.

## Cerradas (acordadas)

### D1 — Upper Leech Point (ULP) en J/70
- **Decisión:** cuando la clase define ULP por “equidistancia”, se interpreta como **equidistancia por longitud de arco (arc length)** sobre la baluma.
- **Motivo:** es consistente con ERS para puntos de baluma (quarter/half/3q) que se definen por equidistancia a lo largo del borde.

### D2 — Bolsillos de sables (batten pockets) y restricción de baluma (mayor)
- **Decisión:** implementar la restricción de baluma tipo J/70 con la opción **(b) simplificada** (sin modelar geometría completa del pocket).
- **Implementación propuesta:** usar los puntos/estaciones de batten provistos por la clase (p.ej. distancias desde el head a centros/posiciones) para construir segmentos límite y restringir el roach.
- **Motivo:** reduce complejidad sin perder el control principal sobre “no abultar” la baluma.

### D3 — Altura del clew del foque (parámetro de diseño)
- **Decisión:** el foque incluye un parámetro de diseño `jib_clew_height` (m) o equivalente adimensional.
- **Rango inicial acordado:** 0.10–0.40 m sobre cubierta (boat frame, z vertical).
- **Nota:** en el vector canónico se recomienda usar `jib_clew_height_frac = jib_clew_height / jib_luff_len`.

### D4 — Mast rake
- `mast_rake_deg` positivo hacia popa (+x) y **fijo** (solo posicionamiento, fuera del vector ML).

## Abiertas (por cerrar)

### O1 — Curvatura del mástil (mast bend) y curvatura del grátil (luff curve)
- **Decisión:** incluir **mast bend** desde el inicio como parámetro de trim.
- `luff curve` del paño (en el planform 2D) queda fuera del MVP.

### O2 — Parámetros de pose (sheeting / boom angle)
- **Decisión:** incluir desde el inicio ángulos globales de trim (boom/sheet) como parámetros de pose.

### O3 — Rangos iniciales de twist/camber/camber_pos
- Definir rangos de diseño realistas y límites para evitar geometrías degeneradas.
