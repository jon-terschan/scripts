#!/bin/bash
#SBATCH --job-name=st2_als_metrics
#SBATCH --array=1-9            # EDIT: number of normalized tiles
#SBATCH --account=project_2001208
#SBATCH --time=01:00:00          # usually much faster than stage 1
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=5G
#SBATCH --partition=small
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=/scratch/project_2001208/Jonathan/ALS/stage2/logs/out/%A_%a.txt
#SBATCH --error=/scratch/project_2001208/Jonathan/ALS/stage2/logs/err/%A_%a.txt

module load r-env

# tile list contains normalized LAZ paths
TILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" tiles.txt)

srun apptainer_wrapper exec \
  Rscript st2_metrics.R "$TILE"
