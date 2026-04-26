#!/bin/bash
#SBATCH --job-name=notebook_test
#SBATCH --partition=nvidia
#SBATCH --output=logs/notebook_%j.log
#SBATCH --gres=gpu:a100:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=80G
#SBATCH --time=1:00:00

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

module purge
module load miniconda

# Set this to your conda environment name before submitting.
ENV_NAME="notebook-env"
if [[ -z "${ENV_NAME}" || "$ENV_NAME" == "your_env_name" ]]; then
  echo "Please set ENV_NAME in run_notebook.sh to a real conda env name."
  exit 1
fi

source "$(conda info --base)/etc/profile.d/conda.sh"
if ! conda run -n "$ENV_NAME" python -c "import sys" >/dev/null 2>&1; then
  echo "Conda environment '$ENV_NAME' not found."
  echo "Create it first with:"
  echo "  conda create -n $ENV_NAME python=3.11 -y"
  echo "  conda run -n $ENV_NAME python -m pip install nbconvert torch matplotlib requests"
  exit 1
fi

# Ensure notebook dependencies exist in this environment.
if ! conda run -n "$ENV_NAME" python -c "import nbconvert" >/dev/null 2>&1; then
  echo "Installing missing package: nbconvert"
  conda run -n "$ENV_NAME" python -m pip install nbconvert
fi

if ! conda run -n "$ENV_NAME" python -c "import torch" >/dev/null 2>&1; then
  echo "Installing missing package: torch"
  conda run -n "$ENV_NAME" python -m pip install torch
fi

if ! conda run -n "$ENV_NAME" python -c "import matplotlib" >/dev/null 2>&1; then
  echo "Installing missing package: matplotlib"
  conda run -n "$ENV_NAME" python -m pip install matplotlib
fi

if ! conda run -n "$ENV_NAME" python -c "import requests" >/dev/null 2>&1; then
  echo "Installing missing package: requests"
  conda run -n "$ENV_NAME" python -m pip install requests
fi

if ! conda run -n "$ENV_NAME" python -c "import ipykernel" >/dev/null 2>&1; then
  echo "Installing missing package: ipykernel"
  conda run -n "$ENV_NAME" python -m pip install ipykernel
fi

# Ensure a python3 kernelspec exists in this environment for nbconvert --execute.
conda run -n "$ENV_NAME" python -m ipykernel install --user --name python3 --display-name "Python 3" >/dev/null 2>&1 || true

conda run -n "$ENV_NAME" python -m nbconvert \
  --to notebook \
  --execute "Assignment 4 Machine Learning.ipynb" \
  --output "executed_Assignment 4 Machine Learning.ipynb"