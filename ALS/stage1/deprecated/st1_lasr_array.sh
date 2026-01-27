#!/bin/bash
#SBATCH --job-name=lasr_array #job name
#SBATCH --array=1-4 #number of batch jobs in array, EDIT
#SBATCH --account=project_2001208 #billing project
#SBATCH --time=03:00:00 #timeout
#SBATCH --cpus-per-task=1 #we run sequentially on one CPU
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=3G #mem per CPU
#SBATCH --partition=small
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=/scratch/project_2001208/Jonathan/ALS/stage1/test/logs/out/%A_%a.txt
#SBATCH --error=/scratch/project_2001208/Jonathan/ALS/stage1/test/logs/err/%A_%a.txt

module load r-env

# -------------------------
# Centralised TMPDIR
# -------------------------
BASE_TMP=/scratch/project_2001208/Jonathan/ALS/stage1/test/tmp
JOB_TMP=${BASE_TMP}/${SLURM_ARRAY_JOB_ID}/task_${SLURM_ARRAY_TASK_ID}

mkdir -p "$JOB_TMP"
export TMPDIR="$JOB_TMP"

# -------------------------
# Pick tile
# -------------------------
TILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" tiles.txt)

echo "Job ID:        $SLURM_JOB_ID"
echo "Array task:   $SLURM_ARRAY_TASK_ID"
echo "Tile:         $TILE"
echo "TMPDIR:       $TMPDIR"

# -------------------------
# Run R
# -------------------------
srun apptainer_wrapper exec \
  Rscript --no-save st1_lasr_array.R "$TILE"
