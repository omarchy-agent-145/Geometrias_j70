# SPEC — Geometrias_j70 (Generador paramétrico de velas J/70)

## 0) Propósito
Construir un generador **100% Python** capaz de crear la geometría 3D completa de:
- **Mayor (mainsail)**
- **Foque (headsail/jib)**

…en formatos triangulados **listos para OpenFOAM/snappyHexMesh** (p.ej. STL/OBJ), con:
- **parametrización explícita y consistente** (vector de parámetros) para dataset/ML,
- **cumplimiento reglamentario** (dimensiones 2D medibles),
- **reproducibilidad** (misma entrada → misma malla STL),
- validaciones automáticas (mediciones, calidad de superficie).

## 1) Alcance (Scope)
### Incluye
- Generación de **planform 2D** reglamentario (contorno en plano) para mayor y foque.
- Generación de **flying shape 3D** mediante **loft por secciones** (estaciones en altura).
- Conversión a **superficie con espesor pequeño** (thin solid) y cierre de bordes (watertight), para robustez en snappyHexMesh.
- Export a **STL (ASCII o binario)** y/o **OBJ**.
- Export de **metadata** (JSON/YAML) con parámetros, versión de reglas, hash git.
- Herramientas CLI para generar lotes (batch) y para validar.

### No incluye (por ahora)
- FSI/membrana con trim (cunningham, backstay, etc.) acoplado.
- Panelización real de velas (seams) y construcción detallada.
- Geometría completa del rig/casco (solo velas; opcionalmente superficies simplificadas para mástil/botavara en el futuro).

## 2) Usuarios y casos de uso
- **CFD**: generar velas con variación controlada (twist/camber) para correr OpenFOAM.
- **ML/Surrogate**: generar miles de geometrías + vector de parámetros consistente para entrenar modelo predictivo de fuerzas.

## 3) Convenciones y sistema de coordenadas
Definir una convención fija (crítica para dataset):
- Unidades: **metros** (internamente). Input/Output permite mm pero se normaliza.

### 3.1 Marcos de referencia (decisión de diseño)
Usaremos dos marcos:

1) **Sail frame (medición/ERS)**: marco local por vela, pensado para que la medición ERS sea directa.
   - `z`: a lo largo del grátil (luff), con `tack` en z=0.
   - `x`: desde el grátil hacia la baluma (dirección de cuerda).
   - `y`: normal para espesor (barlovento/sotavento).

2) **Boat/Rig frame (CFD)**: marco global donde se posicionan mayor y foque para OpenFOAM.
   - En este marco se define la **geometría del aparejo** (mástil/estay) y se aplican transformaciones rígidas a las velas.

La superficie media se genera en el **espacio (x,y,z)** del sail frame mediante secciones 2D en el plano **x–y** para diferentes alturas `z`.

- `x`: dirección de cuerda (desde el grátil hacia la baluma).
- `y`: dirección normal al "plano medio" (aquí vive la **curvatura/camber** de la sección).
- `z`: altura (a lo largo del grátil).

Luego se aplica un espesor pequeño creando una superficie doble y cerrando el borde (ver §7). **El espesor no se aplica como ±y constante**, sino como un offset aproximadamente normal a la superficie media.

### 3.2 Parámetros de aparejo (rig_params) para posicionamiento
Las reglas de velas no fijan la posición relativa mástil–estay; por lo tanto el proyecto define un bloque `rig_params` (con defaults J/70 y documentados) que controla el **posicionamiento**.

**Decisión**: `rig_params` se considera **fijo** para un conjunto de experimentos y **no** forma parte del vector canónico de ML (se guarda como metadata para reproducibilidad).
- Línea del mástil (incluye rake).
  - Inputs mínimos: `mast_base_point`, `mast_rake_deg`, `mast_len`.
  - Puntos derivados: `mast_tack_point` (=base) y `mast_head_point` (=base + mast_len·dir).
- Línea del estay de proa.
  - Inputs mínimos: `I`, `J`.
  - Puntos derivados (MVP): `forestay_tack_point=(J,0)` y `forestay_head_point` como el punto sobre el mástil a distancia `I` desde la base (con rake aplicado).
- (Opcional) `gooseneck_height` si se quiere separar tack de mayor de la referencia z=0.

Con esto, el ángulo del foque respecto al mástil **se deriva** geométricamente de esas dos líneas.

## 4) Reglas: qué se debe cumplir (MVP)
### 4.1 Mayor (mainsail) — constraints
A partir de J/70 Class Rules 2026, Sección G:
- Luff length (máx)
- Leech length (máx)
- Foot length (máx)
- Widths: top, upper, 3/4, 1/2, 1/4 (máx)
- Restricción adicional: **leech no puede extenderse aft** de rectas entre ciertos puntos (por tramos batten-pocket).

**Nota**: la especificación de “upper leech point” aparece en la regla; su definición se debe implementar en el medidor.

### 4.2 Foque (headsail) — constraints
- Luff length (máx)
- Luff perpendicular (LP) (máx)
- Widths: top, 3/4, 1/2, 1/4 (máx)

**Importante**: el reglamento no entrega explícitamente foot/leech máximos en la tabla; el software debe definir un planform que respete las medidas existentes.

Parámetro de diseño adicional (para cerrar el problema geométrico):
- `jib_clew_height` (m, en boat frame; rango inicial 0.10–0.40 m sobre cubierta) o alternativamente `jib_clew_height_frac`.

### 4.3 Interpretación/Medición (ERS) — LITERAL
Para automatizar cumplimiento, necesitamos un **módulo de medición ERS literal** ("measurer"):
- Dado un contorno 2D, computa magnitudes **según definiciones ERS**.

Definiciones clave (ERS 2025–2028, Part 2):
- `Head Point`, `Tack Point`, `Clew Point` (intersecciones de bordes extendidos si hace falta).
- `Leech Length`: distancia **head→clew**.
- `Half Leech Point`: punto en la baluma equidistante (por longitud de baluma) de head y clew.
- `Three-Quarter Leech Point`: punto en la baluma equidistante (por longitud de baluma) de head y **half leech point**.
- `Quarter Leech Point`: punto en la baluma equidistante (por longitud de baluma) de **half leech point** y clew.
- `Upper Leech Point`: punto en la baluma a distancia especificada desde head (la clase puede redefinirlo; J/70 define un ULP particular para el "upper width").
- `Quarter/Half/Three-Quarter Width` (mainsail + headsail): **distancia mínima** entre el leech point correspondiente y el grátil.
- `Top Width` (mainsail + headsail): distancia entre `Head Point` y `Aft Head Point`.
- `Luff Perpendicular (LP)`: distancia mínima entre `Clew Point` y el grátil.

**Decisión de diseño**: el generador no asume que “estación en altura = leech point”. En lugar de eso:
- define el planform,
- **mide con ERS**,
- ajusta parámetros (si hace falta) hasta cumplir.

## 5) Filosofía de parametrización (clave para ML)
Separar en dos capas **explícitas y exportables por separado** (requisito del proyecto):

### Capa A — Planform 2D ("corte", cumplimiento reglas)
Parámetros que controlan el **contorno** y, por tanto, las medidas 2D. Esta capa representa el **tamaño físico** de la vela (planform) dentro del reglamento.

Salida asociada:
- `planform_params` (vector)
- `planform_measurements` (ERS literal)

### Capa B — Trim 3D (flying shape + pose)
Parámetros que controlan la geometría 3D para un planform dado.

Se dividen en dos sub-bloques (pero ambos se consideran *trim*):

1) **Shape (deformación aerodinámica)**
- `twist(η)`, `camber(η)`, `camber_pos(η)`

2) **Pose / trim rígido (ángulos globales)**
- Mayor: `main_boom_angle_deg` (rotación de la mayor alrededor de su grátil/mástil)
- Foque: `jib_sheet_angle_deg` (rotación del foque alrededor del estay)

3) **Rig deformation (trim estructural simplificado)**
- `mast_bend_params` que definen una curva de desplazamiento del mástil en el plano de la vela (ver §6.3.x).

Salida asociada:
- `shape_params` (vector)
- `pose_params` (vector)
- (opcional) `section_curves` (perfiles 2D por estación)

Esto permite entrenar y usar el surrogate de forma jerárquica:
- Optimizar **diseño**: variar `planform_params`.
- Optimizar **trim**: variar `shape_params` condicionado al planform.
- Evaluar desempeño: variar condiciones de viento y ángulos de operación por separado.

Nota: el planform aquí representa el contorno del paño; la panelización/estructura real de un velamen no se modela en el MVP.

## 6) Parametrización propuesta (MVP)
### 6.1 Mayor — Planform 2D
**Entrada objetivo**: generar un contorno que cumpla máximos.

Representación recomendada:
- Grátil (luff) como curva paramétrica L(u), u∈[0,1] con longitud objetivo `luff_len`.
  - MVP: luff recto.
  - Param opcional: `luff_curve_amp` (curvatura del grátil en x).
- Pujamen (foot) como curva simple (recta o spline suave).
- Baluma (leech) como **B-spline** en x–z, con control parametrizado por **leech-points**.

**Parámetros mínimos (propuestos):**
- `main_luff_len` (m)
- `main_foot_len` (m)
- `main_leech_len` (m)
- `main_width_top`, `main_width_upper`, `main_width_3q`, `main_width_half`, `main_width_1q` (m)
- Parámetros de suavidad/forma entre checkpoints (p.ej. `roach_shape_kappa`)

**Estrategia de construcción:**
- Fijar `tack=(0,0)`, `head=(0, main_luff_len)`.
- Definir `clew` mediante `main_foot_len` en x y z=0 (o permitir clew height si se modela un foot no horizontal).
- Construir baluma como spline que pase por puntos a definir en los leech points.
- Ajustar spline para que:
  - widths en leech points sean ≤ máximos,
  - leech length ≤ máximo,
  - se cumpla la restricción “no más atrás que rectas” (por segmentos).

### 6.2 Foque — Planform 2D
La tabla define Luff + LP + widths. Falta unívocamente la posición del clew (altura). Se propone agregar un parámetro geométrico adicional:

**Parámetros mínimos (propuestos):**
- `jib_luff_len` (m)
- `jib_LP` (m)
- `jib_width_top`, `jib_width_3q`, `jib_width_half`, `jib_width_1q` (m)
- `jib_clew_height_frac` ∈ (0,1) — fracción de altura del clew sobre el tack respecto al luff.

**Construcción sugerida:**
- Luff entre `tack` y `head`.
- Clew a una altura `z_clew = jib_clew_height_frac * jib_luff_len`.
- Impone que el LP (perpendicular al luff) en el clew sea el valor deseado.
- Construye baluma con spline que cumpla widths.

### 6.3 Forma 3D por secciones (mayor y foque)
Definir estaciones en altura `η=z/H`, η∈[0,1].

En cada estación:
- Cuerda `c(η)` viene del planform.
- Definir camber (draft) y posición de draft:
  - `camber(η)` como fracción de cuerda (ej. 0.08 = 8%).
  - `camber_pos(η)` como fracción de cuerda (0–1).
- Definir twist:
  - `twist(η)` en grados, como rotación de la sección alrededor de la línea del grátil/estay local.

**Parametrización compacta (recomendada para ML):**
Representar cada función con pocos coeficientes:
- `camber(η)`: spline cúbica con Nknots (p.ej. 4–6) o polinomio (p.ej. 3er orden) con límites.
- `camber_pos(η)`: idem.
- `twist(η)`: idem.

De este modo el vector de parámetros es de dimensión fija (ideal para red).

**Sección 2D (curvatura):**
- Usar una línea de curvatura tipo “NACA 4-digit camber line” o polinomio piecewise que garantice suavidad C1/C2.
- Opción: permitir asimetría controlada — fuera de MVP.

#### 6.3.1 Pose (sheet/boom angles)
Además de `twist(η)`, se define un ángulo global por vela:
- `main_boom_angle_deg`: rotación rígida de toda la mayor alrededor del grátil (mástil).
- `jib_sheet_angle_deg`: rotación rígida de todo el foque alrededor del grátil (estay).

Motivo: `twist(η)` controla variación relativa con la altura; el ángulo global controla el “offset” de trim.

#### 6.3.2 Mast bend (trim estructural simplificado)
Se incorpora un desplazamiento del punto de anclaje del grátil de la mayor sobre el mástil:
- Definir una función `mast_bend_x(ζ)` con `ζ=z/mast_len`.
- MVP (baja dimensión):
  - `mast_bend_amp_m` (amplitud máxima, m)
  - forma fija: `mast_bend_x(ζ) = mast_bend_amp_m * sin(pi*ζ)`
  - con `mast_bend_x(0)=mast_bend_x(1)=0`.

La mayor se construye por estaciones: en cada z se traslada la sección en `x` según `mast_bend_x(ζ)` antes de aplicar el loft.

Nota: esto modela el efecto geométrico del bend en la mayor sin resolver FSI.

## 7) Espesor y watertight
snappyHexMesh es más robusto con superficies cerradas.

**MVP**:
- `thickness` (m) constante (p.ej. 0.002).
- Generar una **superficie media** (con camber y twist).
- Crear dos superficies offset a distancia `±thickness/2` usando un desplazamiento **aprox. normal a la superficie** (por triángulo o por vértice con normal suavizada), y cerrar el borde con una banda triangulada.
- Salida: 1 STL watertight por vela.

Motivo: como el camber vive en `y`, un offset `±y` constante no representa espesor real y puede introducir artefactos geométricos.

## 8) Requisitos de output para OpenFOAM
- Export a `*.stl` (preferido) y/o `*.obj`.
- Normales consistentes (orientación definida; p.ej. normal hacia +y).
- Escala en metros.
- Nomenclatura:
  - `j70_main_<id>.stl`
  - `j70_jib_<id>.stl`

Ubicación esperada en un caso OpenFOAM:
- `constant/triSurface/j70_main_....stl`

## 9) Validaciones automáticas
### 9.1 Validación reglamentaria
- Cálculo de medidas 2D y chequeo ≤ máximos (por vela).
- Reporte detallado: qué medida falla y por cuánto.

### 9.2 Validación geométrica
- Watertightness (sin agujeros).
- Self-intersections (idealmente none).
- Calidad de triángulos (área mínima, ángulo mínimo opcional).

### 9.3 Validación OpenFOAM
- Script opcional que ejecute `surfaceCheck` (si está disponible en el entorno).

## 10) Interface de usuario (CLI)
Propuesta de comandos:
- `geometrias-j70 generate --config config.yaml --out out_dir/`
- `geometrias-j70 validate --stl path.stl --rules ruleset.yaml`
- `geometrias-j70 batch --sampler lhs --n 1000 --seed 123 --out dataset/`

## 11) Configuración y reglasets
- `rulesets/j70_2026.yaml` con todos los máximos/mínimos usados.
- `configs/*.yaml` para definir una geometría o un barrido.

## 12) Sampling para dataset (ML)
Requerimos un módulo de sampling con:
- random uniforme con límites,
- Latin Hypercube Sampling (LHS),
- barridos en malla (grid) para sanity checks.

### 12.1 Estructura jerárquica de muestras (requisito)
Para cada **planform** se deben poder generar múltiples **trims/flying-shapes**.

- Nivel 1: sample `planform_params` → genera planform legal + mediciones ERS.
- Nivel 2: sample `shape_params` condicionados al planform → genera geometría 3D.

Esto facilita entrenar modelos tipo:
- `F = f(planform_params, shape_params, wind_params)`

### 12.2 Artefactos por muestra
Cada muestra (planform + shape) debe producir:
- `planform_params_m.json` (metros)
- `planform_params_hat.json` (normalizado por máximos reglamentarios)
- `shape_params_deg_or_frac.json` (twist en °; camber/camber_pos como fracción de cuerda)
- `pose_params_deg.json` (ángulos globales boom/sheet en °)
- `mast_bend_params_m.json` (parámetros de bend en m)
- `trim_params_hat.json` (vector canónico para ML; ver `docs/ML_VECTOR.md`)
- `wind_params.json` (cuando aplique en el pipeline CFD)
- `rig_params.json` (siempre; fijo para posicionamiento)
- `geometry_main.stl`, `geometry_jib.stl`
- `measurements_main.json`, `measurements_jib.json` (ERS literal)
- `manifest.json` (git commit, timestamp, rulesets, semilla)

## 13) Estructura del repositorio (propuesta)
- `geometrias_j70/`
  - `planform/` (2D)
  - `sections/` (2D camber line)
  - `loft/` (3D surface)
  - `thicken/` (espesor y cierre)
  - `export/` (STL/OBJ)
  - `measure/` (mediciones tipo ERS)
  - `sampling/`
- `scripts/` (entrypoints)
- `tests/` (unit tests: medición, planform, export)

## 14) Criterios de éxito (Definition of Done)
MVP exitoso cuando:
1) Se puede generar una mayor y un foque en STL watertight.
2) El validador reporta medidas 2D **≤ máximos** del ruleset.
3) snappyHexMesh puede leer el STL (al menos en un caso de prueba).
4) El pipeline batch genera N geometrías con metadata y parámetros consistentes.

## 15) Riesgos y decisiones pendientes
- Implementación exacta de ERS (leech points / width measurement) vs aproximación.
- Para foque: definición geométrica extra del clew (altura) para cerrar el problema.
- Rangos realistas de camber/twist para dataset (evitar geometrías degeneradas).

---

## Próximas decisiones (para cerrar especificación)
1) **Decidido**: medición **ERS literal** desde el inicio (referencia: ERS 2025–2028).
2) ¿Cuántas estaciones por altura y cuántos coeficientes por función (twist/camber/pos)?
3) ¿Qué rango de camber (%) y twist (°) consideramos “válido” para dataset inicial?
