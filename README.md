
# Automated Molecular Docking Pipeline

![Bash](https://img.shields.io/badge/Bash-Script-green)
![AutoDock Vina](https://img.shields.io/badge/AutoDock-Vina-blue)
![Open Babel](https://img.shields.io/badge/Open-Babel-orange)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)

An automated bash script for high-throughput molecular docking using AutoDock Vina and Open Babel. Processes multiple ligands against a protein receptor with minimal user intervention.

## 🚀 Features

- **Batch Processing**: Automatically docks multiple ligands in sequence
- **File Format Support**: Handles SDF, MOL2, and PDB files
- **Complete Pipeline**: From file preparation to complex generation
- **Pose Generation**: Creates multiple binding poses per ligand
- **Results Organization**: Structured output with comprehensive logging
- **Performance Optimization**: Multi-threaded docking with configurable parameters

## 📋 Prerequisites

### Software Requirements
- **AutoDock Vina** (1.1.2 or compatible)
- **Open Babel** (3.0.0 or later)
- **Bash** shell environment

### System Requirements
- Linux/Unix-based operating system
- Multi-core CPU (8+ cores recommended)
- 4GB+ RAM for processing multiple ligands

## 🛠️ Installation

1. **Clone the repository**:
```bash
git clone https://github.com/yourusername/automated-docking.git
cd automated-docking
```

2. **Install dependencies**:
```bash
# Install Open Babel
sudo apt-get install openbabel  # Ubuntu/Debian
# or
brew install open-babel         # macOS

# Download AutoDock Vina
wget http://vina.scripps.edu/download/autodock_vina_1_1_2_linux_x86.tgz
tar -xzf autodock_vina_1_1_2_linux_x86.tgz
```

3. **Make script executable**:
```bash
chmod +x Auto-dock.sh
```

## ⚙️ Configuration

### Edit Script Parameters
Modify the hardcoded parameters in `Auto-dock.sh`:

```bash
# Receptor file path
RECEPTOR_PDB_FILE="/path/to/your/receptor.pdb"

# Ligand directory
LIGAND_DIR="/path/to/your/ligands"

# Vina executable paths
VINA_EXECUTABLE="/path/to/vina"
VINA_SPLIT_EXECUTABLE="/path/to/vina_split"

# Docking box coordinates (customize for your receptor)
CENTER_X="37.749"    # X-center of binding site
CENTER_Y="10.505"    # Y-center of binding site  
CENTER_Z="48.431"    # Z-center of binding site
SIZE_X="40.279"      # Box size in X-direction
SIZE_Y="27.291"      # Box size in Y-direction
SIZE_Z="29.313"      # Box size in Z-direction

# Performance settings
CPU_THREADS="8"      # Number of CPU threads to use
```

## 📁 Input File Preparation

### Receptor File
- **Format**: PDB file
- **Preparation**: Remove water molecules, add hydrogens
- **Naming**: Any valid filename (e.g., `receptor.pdb`)

### Ligand Files
- **Formats**: SDF or MOL2 files
- **Location**: Place all ligand files in the specified `LIGAND_DIR`
- **Naming**: Files should have meaningful names (used in output)

### Example Directory Structure
```
project/
├── Auto-dock.sh
├── receptor.pdb
└── ligands/
    ├── compound1.sdf
    ├── compound2.mol2
    └── compound3.sdf
```

## 🎯 Usage

### Basic Execution
```bash
./Auto-dock.sh
```

### Step-by-Step Process

1. **Script initializes** and creates output directory with timestamp
2. **Receptor preparation**:
   - Adds hydrogens and charges
   - Converts PDB → PDBQT format
3. **Ligand processing** (for each ligand file):
   - Converts SDF/MOL2 → PDBQT format
   - Runs AutoDock Vina docking
   - Generates multiple binding poses
4. **Post-processing**:
   - Splits multi-pose results
   - Creates protein-ligand complexes
   - Organizes results by ligand
5. **Results summary**:
   - Extracts binding affinities
   - Ranks top 5 compounds

## 📊 Output Structure

```
output_2024-01-15_14-30-25/
├── prepared_receptor.pdbqt
├── prepared_ligands/
│   ├── compound1.pdbqt
│   └── compound2.pdbqt
├── vina_outputs/
│   ├── compound1/
│   │   ├── compound1_log.txt
│   │   └── poses/
│   │       ├── pose_1_complex.pdb
│   │       ├── pose_2_complex.pdb
│   │       └── ...
│   └── compound2/
│       └── ...
├── vina_config.txt
└── docking_run.log
```

### Output Files Description

- **prepared_receptor.pdbqt**: Receptor in Vina-ready format
- **prepared_ligands/**: Converted ligand files
- **poses/**: Protein-ligand complex structures (PDB format)
- ***_log.txt**: Detailed docking scores and energies
- **docking_run.log**: Complete script execution log

## 🔬 Docking Parameters

### Default Vina Configuration
```ini
receptor = prepared_receptor.pdbqt
center_x = 37.749
center_y = 10.505  
center_z = 48.431
size_x = 40.279
size_y = 27.291
size_z = 29.313
num_modes = 9          # Number of poses to generate
exhaustiveness = 14    # Search thoroughness
```

### Customization
Edit the script to modify docking parameters:
```bash
# In the configuration file generation section
cat > "$CONFIG_FILE" << EOL
receptor = $PREPARED_RECEPTOR_FILE
center_x = $CENTER_X
center_y = $CENTER_Y
center_z = $CENTER_Z
size_x = $SIZE_X
size_y = $SIZE_Y
size_z = $SIZE_Z
num_modes = 20         # Increase number of poses
exhaustiveness = 24    # More exhaustive search
energy_range = 4       # Energy range for clustering
EOL
```

## 📈 Results Interpretation

### Binding Affinity Ranges
- **Excellent**: < -8.0 kcal/mol
- **Good**: -8.0 to -6.0 kcal/mol
- **Moderate**: -6.0 to -4.5 kcal/mol  
- **Weak**: > -4.5 kcal/mol

### Key Metrics in Output
- **Binding affinity** (kcal/mol): Primary docking score
- **RMSD values**: Pose variability and clustering
- **Pose coordinates**: 3D binding modes for visualization

## 🐛 Troubleshooting

### Common Issues

1. **"obabel command not found"**
   ```bash
   sudo apt-get install openbabel  # Install Open Babel
   ```

2. **Vina executable not found**
   - Update `VINA_EXECUTABLE` path in script
   - Ensure file has execute permissions: `chmod +x vina`

3. **Receptor file not found**
   - Check `RECEPTOR_PDB_FILE` path in script
   - Verify file exists and is readable

4. **No ligands processed**
   - Confirm ligand files are in correct directory
   - Check file extensions (.sdf, .mol2)

5. **Docking failures**
   - Verify docking box covers binding site
   - Check receptor preparation (hydrogens, charges)
   - Ensure ligand structures are valid

### Debug Mode
Add debug output by modifying the script:
```bash
# Add after line 1
set -x  # Enable debug mode
```

## 🤝 Contributing

Contributions are welcome! Please feel free to:
- Report bugs and issues
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **AutoDock Vina Team** at The Scripps Research Institute
- **Open Babel Community** for chemical format conversion tools
- Contributors to open-source computational chemistry tools

## 📚 References

1. Trott, O., & Olson, A. J. (2010). AutoDock Vina: improving the speed and accuracy of docking with a new scoring function, efficient optimization and multithreading. Journal of computational chemistry, 31(2), 455-461.

2. O'Boyle, N. M., et al. (2011). Open Babel: An open chemical toolbox. Journal of Cheminformatics, 3(1), 33.

---

**Note**: This tool is for research and educational purposes. Always validate docking results with experimental data when available.
```

This README provides:

1. **Comprehensive documentation** of the docking pipeline
2. **Clear installation and setup instructions**
3. **Detailed usage examples**
4. **Troubleshooting guide** for common issues
5. **Professional formatting** with badges and sections
6. **Scientific context** for result interpretation
7. **GPL v3 license** compliance
8. **Proper attribution** to software tools used

The README is structured to help users quickly understand, install, and use the automated docking script effectively.
