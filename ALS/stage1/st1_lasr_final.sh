#!/bin/bash
#SBATCH --job-name=lasr_array_buffer
#SBATCH --array=1-9 #number of batch jobs in array, EDIT
#SBATCH --account=project_2001208 #billing project
#SBATCH --time=04:00:00 #timeout
#SBATCH --cpus-per-task=1 #we run sequentially on one CPU
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=3G #mem per CPU
#SBATCH --partition=small
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=/scratch/project_2001208/Jonathan/ALS/stage1/test/logs/out/%A_%a.txt
#SBATCH --error=/scratch/project_2001208/Jonathan/ALS/stage1/test/logs/err/%A_%a.txt

module load r-env

TILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" tiles.txt)

srun apptainer_wrapper exec \
  Rscript st1_lasr_final.R "$TILE"