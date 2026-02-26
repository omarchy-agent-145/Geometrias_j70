# Convenciones de ejes y signos (boat frame / sail frame)

Este documento fija convenciones para evitar ambigüedad en geometría, trim y viento.

## 1) Boat frame (marco global del barco) — **right-handed**

Usaremos un sistema **tridimensional** y **diestro**:
- **x**: hacia proa (forward)
- **y**: hacia babor (port)
- **z**: hacia arriba (up)

Regla: `x × y = z`.

### 1.1 Starboard tack
Trabajaremos (por defecto) en **barco amurado a estribor**:
- El viento viene desde estribor ⇒ componente lateral del viento típicamente hacia **-y**.
- La mayor y el foque normalmente quedan "abiertos" hacia babor ⇒ el clew se desplaza hacia **+y**.

## 2) Sail frame (marco local por vela, para medición/loft)
Cada vela se genera y se mide en un marco local, luego se transforma al boat frame.

Definición recomendada (diestro):
- **s** ("span"): a lo largo del grátil (luff), desde tack → head.
- **c** ("chord"): dirección de cuerda desde el grátil hacia la baluma (leech) en la sección.
- **n** ("normal"): normal de la sección, donde vive la **curvatura/camber** (positiva hacia sotavento según convención del caso).

En implementación podemos mapear (c,n,s) a (x,y,z) del sail frame.

## 3) Signo de ángulos (convención única)
Todos los ángulos se definen con la **regla de la mano derecha** alrededor del eje indicado.

### 3.1 Ángulos globales de trim (pose)
- `main_boom_angle_deg`: rotación rígida de la mayor alrededor del eje del grátil (eje del mástil en boat frame).
- `jib_sheet_angle_deg`: rotación rígida del foque alrededor del eje del grátil (eje del estay en boat frame).

**Referencia (0°)**: vela alineada con la **crujía** (plano x–z; clew en y=0).

**Signo**: positivo si la rotación desplaza el clew hacia **+y (babor)**.

Esto es consistente con starboard tack típico (velas hacia babor ⇒ ángulos positivos).

## 4) Viento (recomendación para dataset)
Para evitar confusiones, definir AWA/AWS en boat frame con convención explícita, p.ej.:
- `AWA_deg`: ángulo del viento aparente medido en el plano x–y desde +x (proa) con signo positivo hacia +y (babor).

Con esta convención, **starboard tack** corresponde típicamente a `AWA_deg < 0`.

Si prefieres `AWA_deg > 0` para estribor, se puede usar otra convención, pero debe fijarse y documentarse igual de explícita.
