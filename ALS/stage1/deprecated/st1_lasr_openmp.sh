#!/bin/bash
#SBATCH --job-name=lasr_test         # Job name
#SBATCH --account=project_2001208         # Billing project, has to be defined!
#SBATCH --time=72:00:00             # Max. duration of the job
#SBATCH --cpus-per-task=4
#SBATCH --nodes=1
#SBATCH --ntasks=1 # number of tasks
#SBATCH --mem-per-cpu=4G            # Memory to reserve per core
#SBATCH --partition=small           # Job queue (partition)
#SBATCH --mail-type=BEGIN,END,FAIL          # Uncomment to enable mail
#SBATCH --output=output_%j.txt
#SBATCH --error=errors_%j.txt

# Load r-env
module load r-env

# Clean up .Renviron file in home directory
#if test -f ~/.Renviron; then
#    sed -i '/TMPDIR/d' ~/.Renviron
#fi

# Specify a temp folder path
#echo "TMPDIR=/scratch/project_2001208/Jonathan/ALS/stage1/test/" >> ~/.Renviron

export TMPDIR=/scratch/project_2001208/Jonathan/ALS/stage1/test
mkdir -p "$TMPDIR"

# Match thread and core numbers
# this is important for the apptainer to know how to handle multithreading
export APPTAINERENV_OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# Thread affinity control
export APPTAINERENV_OMP_PLACES=cores
export APPTAINERENV_OMP_PROC_BIND=close

# Run the R script
srun apptainer_wrapper exec Rscript --no-save st1_lasr_openmp.R
