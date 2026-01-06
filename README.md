# Automated Molecular Docking Pipeline

![Bash](https://img.shields.io/badge/Bash-Script-green)
![AutoDock Vina](https://img.shields.io/badge/AutoDock-Vina-blue)
![GNU Parallel](https://img.shields.io/badge/GNU-Parallel-red)
![GPU](https://img.shields.io/badge/GPU-CUDA-brightgreen)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)

High-throughput molecular docking with **parallel processing**, **GPU acceleration**, and **automated visualization**.

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Parallel Processing** | GNU Parallel for concurrent docking jobs |
| **GPU Acceleration** | Vina-GPU support for CUDA-enabled GPUs |
| **Checkpointing** | Resume interrupted runs automatically |
| **External Config** | `docking.conf` for easy configuration |
| **CLI Arguments** | Override settings via command line |
| **CSV Export** | Full results in `summary_results.csv` |
| **Histogram** | Binding affinity distribution chart |
| **Combined SDF** | All best poses in one file |
| **Slurm Support** | HPC cluster job script generator |

## 🚀 Quick Start

```bash
# Basic usage
./Auto-dock.sh -r receptor.pdb -l ./ligands/

# With config file
./Auto-dock.sh -c docking.conf

# GPU mode with 8 concurrent jobs
./Auto-dock.sh -c docking.conf -g -j 8
```

## 📋 Requirements

```bash
# Core (required)
sudo apt install openbabel parallel

# GPU mode (optional)
# Install Vina-GPU from: https://github.com/DeltaGroupNJUPT/Vina-GPU-2.0

# Visualization (optional)
pip install pandas matplotlib
```

## ⚙️ Configuration

### Option 1: Config File
Copy and edit `docking.conf`:
```bash
RECEPTOR_PDB_FILE="/path/to/receptor.pdb"
LIGAND_DIR="/path/to/ligands"
VINA_EXECUTABLE="/path/to/vina"
CENTER_X="37.75"
CENTER_Y="10.50"
CENTER_Z="48.43"
# ... see docking.conf for all options
```

### Option 2: Command Line
```bash
./Auto-dock.sh [OPTIONS]

Options:
  -r FILE     Receptor PDB file
  -l DIR      Ligand directory
  -c FILE     Config file
  -g          Enable GPU mode
  -j NUM      Concurrent jobs (default: 4)
  -t NUM      Threads per job (default: 2)
  -h          Help
```

**Priority:** CLI args > Config file > Script defaults

## 📊 Output Files

```
output_2024-01-15_14-30-25/
├── summary_results.csv      # All docking scores (CSV)
├── scores_histogram.png     # Affinity distribution chart
├── all_docked_hits.sdf      # Combined best poses
├── docking_run.log          # Execution log
├── parallel_jobs.log        # Job status log
└── vina_outputs/
    └── ligand_name/
        ├── ligand_name_log.txt
        └── poses/
            ├── pose_1_complex.pdb
            └── ...
```

## 🖥️ HPC/Slurm Support

Generate cluster job scripts:
```bash
./generate_slurm.sh -c docking.conf -o my_job.sbatch
sbatch my_job.sbatch
```

Auto-calculates `--cpus-per-task` from your config.

## 📈 Binding Affinity Guide

| Range | Interpretation |
|-------|----------------|
| < -8.0 kcal/mol | Excellent |
| -8.0 to -6.0 | Good |
| -6.0 to -4.5 | Moderate |
| > -4.5 | Weak |

## 🔧 Troubleshooting

| Error | Solution |
|-------|----------|
| `obabel not found` | `sudo apt install openbabel` |
| `parallel not found` | `sudo apt install parallel` |
| `Vina not found` | Update path in config |
| Empty histogram | `pip install pandas matplotlib` |

## 📚 References

1. Trott & Olson (2010). AutoDock Vina. *J Comput Chem* 31(2):455-461
2. O'Boyle et al. (2011). Open Babel. *J Cheminform* 3:33
3. Ding et al. (2023). Vina-GPU 2.0. *J Chem Inf Model*

## 📄 License

GPL v3.0 - See [LICENSE](LICENSE)

---

**Author:** Dip Kumar Ghosh ([@Deon-07](https://github.com/Deon-07))
