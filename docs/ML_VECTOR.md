# Vector canónico para ML (inputs del surrogate)

## Objetivo
Definir un **vector de entrada estable numéricamente** y trazable para entrenamiento/inferencia del surrogate.

Decisión: el vector canónico usado por ML será el **normalizado** (adimensional) y siempre se guardará también la versión en unidades físicas (m, °) como metadata.

## Por qué normalizar (justificación)
1) **Estabilidad numérica**: redes entrenan mejor con variables en rangos comparables (≈O(1)).
2) **Sampling consistente**: límites naturales [0,1] para magnitudes con máximos reglamentarios.
3) **Compatibilidad multi-ruleset**: si cambian máximos por año/regla, la normalización conserva interpretación.
4) **Reproducibilidad**: queda explícito qué reglas (máximos) se usaron para construir 
   \(\hat{x}=x/x_{max}\).

## Capas de parámetros (separación diseño vs trim)
Se exportan 2 vectores separados:
- `planform_params_hat`: diseño/corte (cumplimiento reglamentario 2D)
- `trim_params_hat`: trim 3D, subdividido en:
  - `shape_params_hat` (twist/camber/camber_pos)
  - `pose_params_hat` (boom/sheet angles)
  - `mast_bend_params_hat` (bend del mástil)

Y opcionalmente (pipeline CFD):
- `wind_params_hat`: condiciones de viento/operación

## Qué NO entra al vector canónico
- `rig_params` (I, J, mast rake, etc.) se usan para **posicionar** velas en el marco global CFD y se guardan en `manifest.json`/`ruleset.json`, pero no se incluyen en el vector canónico del surrogate (decisión de proyecto para mantener el diseño/trim desacoplados del aparejo).

## Normalización propuesta
### A) Planform (en metros → fracción del máximo reglamentario)
Para cada magnitud reglamentaria con máximo \(x_{max}\):
- \(\hat{x} = x / x_{max}\)

Ejemplos:
- `main.luff_len_hat = main.luff_len_m / main.luff_len_max_m`
- `jib.LP_hat = jib.LP_m / jib.LP_max_m`

### B) Trim params
#### B1) Shape (twist, camber, camber_pos)
**Twist**: normalizar a [-1, 1] usando un rango de diseño fijado (por dataset):
- Definir `twist_min_deg`, `twist_max_deg` (globales por vela) y mapear:
  - \(\hat{\theta} = 2*(\theta-\theta_{min})/(\theta_{max}-\theta_{min}) - 1\)

**Camber y camber position**: ya adimensional (fracción de cuerda):
- `camber_hat = camber_frac` (ej. 0.08 para 8%)
- `camber_pos_hat = camber_pos_frac` (ej. 0.40)

#### B2) Pose (sheet/boom angles)
Normalizar a [-1,1] con rangos definidos:
- `main_boom_angle_deg` en [`boom_min_deg`, `boom_max_deg`]
- `jib_sheet_angle_deg` en [`jibsheet_min_deg`, `jibsheet_max_deg`]

#### B3) Mast bend
MVP: un parámetro físico:
- `mast_bend_amp_m`

Normalización:
- `mast_bend_amp_hat = mast_bend_amp_m / mast_bend_amp_max_m`

(Se recomienda un `mast_bend_amp_max_m` conservador para el dataset inicial.)

### C) Variables que se dejan físicas
Algunas variables se dejan en unidades y se documenta explícitamente:
- `clew_height_frac` ya es adimensional, se deja tal cual.

## Artefactos por muestra (nombres recomendados)
- `planform_params_m.json` (metros)
- `planform_params_hat.json` (normalizado)
- `shape_params_deg_or_frac.json` (twist en °, camber y pos como fracción)
- `shape_params_hat.json` (twist normalizado [-1,1], camber/pos en [0,1])
- `ruleset.json` (versiones + máximos usados)

## Nota sobre interpretabilidad
Para análisis humano (plots/reportes) se usará por defecto la versión en **metros/°**.
Para entrenamiento/inferencia del modelo se usará la versión **hat**.
