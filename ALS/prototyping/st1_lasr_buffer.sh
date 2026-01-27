#!/bin/bash
#SBATCH --job-name=lasr_array_buffer
#SBATCH --array=1-4        # adjust
#SBATCH --account=project_2001208
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3G
#SBATCH --partition=small
#SBATCH --output=/scratch/project_2001208/Jonathan/ALS/logs/out/%A_%a.out
#SBATCH --error=/scratch/project_2001208/Jonathan/ALS/logs/err/%A_%a.err

module load r-env

TILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" tiles.txt)

srun apptainer_wrapper exec \
  Rscript st1_lasr_buffer.R "$TILE"
