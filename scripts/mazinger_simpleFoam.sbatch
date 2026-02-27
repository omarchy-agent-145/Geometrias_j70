#!/usr/bin/env bash
#SBATCH --job-name=foam-simpleFoam
#SBATCH --partition=full
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --time=02:00:00
#SBATCH --output=slurm-%x-%j.out
#SBATCH --error=slurm-%x-%j.err

set -euo pipefail

CASE_DIR="${1:-$SLURM_SUBMIT_DIR}"

# OpenFOAM env (system)
source /usr/lib/openfoam/openfoam2506/etc/bashrc

export OMP_NUM_THREADS=${OMP_NUM_THREADS:-1}

echo "[info] host=$(hostname)"
echo "[info] case=$CASE_DIR"
echo "[info] ntasks=${SLURM_NTASKS:-unset}"
echo "[info] WM_PROJECT_DIR=${WM_PROJECT_DIR:-unset}"

cd "$CASE_DIR"

# (Opcional) generar malla si existe system/blockMeshDict
if [ -f system/blockMeshDict ]; then
  echo "[info] blockMesh"
  blockMesh
fi

# Paralelo si existe system/decomposeParDict
if [ -f system/decomposeParDict ]; then
  echo "[info] decomposePar"
  decomposePar -force

  echo "[info] simpleFoam (parallel)"
  srun -n "${SLURM_NTASKS}" simpleFoam -parallel

  echo "[info] reconstructPar (latestTime)"
  reconstructPar -latestTime
else
  echo "[info] simpleFoam (serial)"
  simpleFoam
fi

echo "[done]"
