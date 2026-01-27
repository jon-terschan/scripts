#!/bin/bash
#SBATCH --job-name=prep_tiles
#SBATCH --account=project_2001208
#SBATCH --partition=small
#SBATCH --time=00:10:00
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --output=logs/prep_tiles_%j.out
#SBATCH --error=logs/prep_tiles_%j.err

module load r-env

Rscript prep_tiles.R
