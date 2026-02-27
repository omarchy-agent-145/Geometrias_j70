# Mazinger (PUC) — Slurm + OpenFOAM (system install)

## OpenFOAM (OpenCFD) disponible en el sistema

Version recomendada (más nueva):

```bash
source /usr/lib/openfoam/openfoam2506/etc/bashrc
simpleFoam -help
```

Otras versiones vistas:
- `/usr/lib/openfoam/openfoam2412`
- `/usr/lib/openfoam/openfoam2212`

> Nota: si `foamVersion` no aparece, no pasa nada; lo importante es `source .../etc/bashrc` para poblar PATH y variables (`WM_PROJECT_DIR`, `FOAM_APPBIN`, etc.).

## Slurm (buenas prácticas)

- No correr solvers en el **login node**.
- Usar `sbatch` (batch) o `srun` (interactivo dentro de una asignación).
- Evitar oversubscription: típicamente `OMP_NUM_THREADS=1` y paralelismo MPI con `--ntasks`.

Comandos útiles:

```bash
sinfo
squeue -u $USER
scontrol show job <jobid>
```

## Template de job

Ver: `scripts/mazinger_simpleFoam.sbatch`.

Ejemplo de uso:

```bash
sbatch scripts/mazinger_simpleFoam.sbatch /path/al/caso
```

El script:
- entra al directorio del caso
- genera malla (si corresponde)
- descompone
- corre solver en paralelo con `srun`
- reconstruye resultados
