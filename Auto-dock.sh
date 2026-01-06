#!/bin/bash

# --- Automated Docking Script ---
# Author: Dip Kumar Ghosh (Deon-07)
# GitHub: https://github.com/Deon-07/automated-docking
# 
# This script prepares a PDB receptor and docks multiple ligands (SDF/MOL2)
# against it using Open Babel and AutoDock Vina. It saves a PDB complex for
# each docking pose into a dedicated folder for each ligand.

# --- Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- HELP FUNCTION ---
show_help() {
    cat << EOF
Automated Molecular Docking Pipeline
Author: Dip Kumar Ghosh (GitHub: Deon-07)

Usage: $0 [OPTIONS]

Options:
  -r FILE     Receptor PDB file
  -l DIR      Ligand directory (SDF/MOL2 files)
  -c FILE     Config file (default: ./docking.conf)
  -g          Enable GPU mode (requires Vina-GPU)
  -j NUM      Concurrent jobs for CPU mode (default: 4)
  -t NUM      Threads per job (default: 2)
  -h          Show this help message

Examples:
  $0 -r protein.pdb -l ./ligands/
  $0 -c my_project.conf
  $0 -r protein.pdb -l ./ligands/ -g
  $0 -c docking.conf -j 8 -t 4

Priority: CLI arguments > Config file > Script defaults
EOF
    exit 0
}

# --- DEFAULT VALUES ---
# These are used if not specified in config file or CLI
DEFAULT_RECEPTOR_PDB_FILE="/path/to/your/receptor.pdb"
DEFAULT_LIGAND_DIR="/path/to/your/ligands"
DEFAULT_VINA_EXECUTABLE="/path/to/vina"
DEFAULT_VINA_SPLIT_EXECUTABLE="/path/to/vina_split"
DEFAULT_CENTER_X="37.7494560252"
DEFAULT_CENTER_Y="10.5055397622"
DEFAULT_CENTER_Z="48.4313435631"
DEFAULT_SIZE_X="40.279181568"
DEFAULT_SIZE_Y="27.2915204756"
DEFAULT_SIZE_Z="29.3130756759"
DEFAULT_CONCURRENT_JOBS="4"
DEFAULT_THREADS_PER_JOB="2"
DEFAULT_USE_GPU="false"
DEFAULT_VINA_GPU_EXECUTABLE="/path/to/Vina-GPU"
DEFAULT_GPU_THREAD_COUNT="auto"

# --- PARSE COMMAND LINE ARGUMENTS ---
CONFIG_FILE_PATH="./docking.conf"
CLI_RECEPTOR=""
CLI_LIGAND_DIR=""
CLI_USE_GPU=""
CLI_CONCURRENT_JOBS=""
CLI_THREADS_PER_JOB=""

while getopts "r:l:c:gj:t:h" opt; do
    case $opt in
        r) CLI_RECEPTOR="$OPTARG" ;;
        l) CLI_LIGAND_DIR="$OPTARG" ;;
        c) CONFIG_FILE_PATH="$OPTARG" ;;
        g) CLI_USE_GPU="true" ;;
        j) CLI_CONCURRENT_JOBS="$OPTARG" ;;
        t) CLI_THREADS_PER_JOB="$OPTARG" ;;
        h) show_help ;;
        \?) echo "Invalid option: -$OPTARG" >&2; show_help ;;
    esac
done

# --- LOAD CONFIG FILE ---
if [ -f "$CONFIG_FILE_PATH" ]; then
    echo "Loading config from: $CONFIG_FILE_PATH"
    source "$CONFIG_FILE_PATH"
fi

# --- APPLY CONFIGURATION (Priority: CLI > Config > Defaults) ---
RECEPTOR_PDB_FILE="${CLI_RECEPTOR:-${RECEPTOR_PDB_FILE:-$DEFAULT_RECEPTOR_PDB_FILE}}"
LIGAND_DIR="${CLI_LIGAND_DIR:-${LIGAND_DIR:-$DEFAULT_LIGAND_DIR}}"
VINA_EXECUTABLE="${VINA_EXECUTABLE:-$DEFAULT_VINA_EXECUTABLE}"
VINA_SPLIT_EXECUTABLE="${VINA_SPLIT_EXECUTABLE:-$DEFAULT_VINA_SPLIT_EXECUTABLE}"
CENTER_X="${CENTER_X:-$DEFAULT_CENTER_X}"
CENTER_Y="${CENTER_Y:-$DEFAULT_CENTER_Y}"
CENTER_Z="${CENTER_Z:-$DEFAULT_CENTER_Z}"
SIZE_X="${SIZE_X:-$DEFAULT_SIZE_X}"
SIZE_Y="${SIZE_Y:-$DEFAULT_SIZE_Y}"
SIZE_Z="${SIZE_Z:-$DEFAULT_SIZE_Z}"
CONCURRENT_JOBS="${CLI_CONCURRENT_JOBS:-${CONCURRENT_JOBS:-$DEFAULT_CONCURRENT_JOBS}}"
THREADS_PER_JOB="${CLI_THREADS_PER_JOB:-${THREADS_PER_JOB:-$DEFAULT_THREADS_PER_JOB}}"
USE_GPU="${CLI_USE_GPU:-${USE_GPU:-$DEFAULT_USE_GPU}}"
VINA_GPU_EXECUTABLE="${VINA_GPU_EXECUTABLE:-$DEFAULT_VINA_GPU_EXECUTABLE}"
GPU_THREAD_COUNT="${GPU_THREAD_COUNT:-$DEFAULT_GPU_THREAD_COUNT}"

# --- DYNAMIC DIRECTORY SETUP ---
# Get the absolute path of the directory where the script is being run
SCRIPT_RUN_DIR=$(pwd)
# Create a unique directory name using the current date and time
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
MAIN_OUTPUT_DIR="${SCRIPT_RUN_DIR}/output_${TIMESTAMP}"

# Define all other output paths to be inside the main output directory
PREPARED_RECEPTOR_FILE="${MAIN_OUTPUT_DIR}/prepared_receptor.pdbqt"
PREPARED_LIGAND_DIR="${MAIN_OUTPUT_DIR}/prepared_ligands"
VINA_OUTPUT_DIR="${MAIN_OUTPUT_DIR}/vina_outputs"
MAIN_LOG_FILE="${MAIN_OUTPUT_DIR}/docking_run.log"
CONFIG_FILE="${MAIN_OUTPUT_DIR}/vina_config.txt"

# --- LOGGING SETUP ---
# Log message function: prints to console and appends to the main log file.
log_message() {
    echo "$1" | tee -a "$MAIN_LOG_FILE"
}

# --- SCRIPT START ---
# Create the main output directory
mkdir -p "$MAIN_OUTPUT_DIR"
# Clear previous log file content and record start time
echo "Automated Docking Script - Dip Kumar Ghosh (Deon-07)" > "$MAIN_LOG_FILE"
echo "Script started on $(date)" >> "$MAIN_LOG_FILE"
start_time=$(date +%s)

log_message "=== Automated Molecular Docking Pipeline ==="
log_message "Author: Dip Kumar Ghosh (GitHub: Deon-07)"
log_message "Repository: https://github.com/Deon-07/automated-docking"
log_message ""

log_message "Input Receptor PDB file: ${RECEPTOR_PDB_FILE}"
log_message "Ligand directory: ${LIGAND_DIR}"

# Create subdirectories for prepared ligands and Vina results
log_message "Creating output directory: ${MAIN_OUTPUT_DIR}"
mkdir -p "$PREPARED_LIGAND_DIR"
mkdir -p "$VINA_OUTPUT_DIR"

# --- Check for Tools and Input Files ---
if ! command -v obabel &> /dev/null; then
    log_message "ERROR: 'obabel' command not found. Please install Open Babel:"
    log_message "  Ubuntu/Debian: sudo apt-get install openbabel"
    log_message "  macOS: brew install open-babel"
    exit 1
fi
if ! command -v parallel &> /dev/null; then
    log_message "ERROR: 'parallel' command not found. Please install GNU Parallel:"
    log_message "  Ubuntu/Debian: sudo apt-get install parallel"
    log_message "  macOS: brew install parallel"
    exit 1
fi
if [ ! -x "$VINA_EXECUTABLE" ]; then
    log_message "ERROR: Vina executable not found or not executable at: $VINA_EXECUTABLE"
    log_message "Please download AutoDock Vina and update the VINA_EXECUTABLE path in the script."
    exit 1
fi
if [ ! -x "$VINA_SPLIT_EXECUTABLE" ]; then
    log_message "ERROR: vina_split executable not found or not executable at: $VINA_SPLIT_EXECUTABLE"
    log_message "Please download AutoDock Vina and update the VINA_SPLIT_EXECUTABLE path in the script."
    exit 1
fi
if [ ! -f "$RECEPTOR_PDB_FILE" ]; then
    log_message "ERROR: Receptor PDB file not found at: $RECEPTOR_PDB_FILE"
    log_message "Please update the RECEPTOR_PDB_FILE path in the script configuration section."
    exit 1
fi
if [ ! -d "$LIGAND_DIR" ]; then
    log_message "ERROR: Ligand directory not found at: $LIGAND_DIR"
    log_message "Please update the LIGAND_DIR path in the script configuration section."
    exit 1
fi

# GPU-specific validation and auto-detection
if [ "$USE_GPU" = "true" ]; then
    if [ ! -x "$VINA_GPU_EXECUTABLE" ]; then
        log_message "ERROR: Vina-GPU executable not found at: $VINA_GPU_EXECUTABLE"
        log_message "Please install Vina-GPU from: https://github.com/DeltaGroupNJUPT/Vina-GPU-2.0"
        exit 1
    fi
    
    # GPU detection and thread count auto-configuration
    if command -v nvidia-smi &>/dev/null; then
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
        log_message "GPU detected: $GPU_NAME"
        
        # Auto-detect optimal thread count if set to "auto"
        if [ "$GPU_THREAD_COUNT" = "auto" ]; then
            # Get CUDA cores (multiprocessors * cores per MP varies by architecture)
            # Using memory as proxy: ~1024 threads per GB of VRAM is a safe heuristic
            GPU_MEMORY_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1 | tr -d ' ')
            if [ -n "$GPU_MEMORY_MB" ] && [ "$GPU_MEMORY_MB" -gt 0 ] 2>/dev/null; then
                # Calculate threads: ~1024 per GB, rounded to power of 2, min 1024, max 32768
                GPU_MEMORY_GB=$((GPU_MEMORY_MB / 1024))
                CALCULATED_THREADS=$((GPU_MEMORY_GB * 1024))
                # Clamp to reasonable range
                if [ "$CALCULATED_THREADS" -lt 1024 ]; then
                    CALCULATED_THREADS=1024
                elif [ "$CALCULATED_THREADS" -gt 32768 ]; then
                    CALCULATED_THREADS=32768
                fi
                GPU_THREAD_COUNT="$CALCULATED_THREADS"
                log_message "  -> Auto-detected GPU threads: $GPU_THREAD_COUNT (based on ${GPU_MEMORY_GB}GB VRAM)"
            else
                GPU_THREAD_COUNT=8192
                log_message "  -> Using default GPU threads: $GPU_THREAD_COUNT"
            fi
        else
            log_message "  -> Using configured GPU threads: $GPU_THREAD_COUNT"
        fi
    else
        log_message "WARNING: nvidia-smi not found. CUDA GPU may not be available."
        if [ "$GPU_THREAD_COUNT" = "auto" ]; then
            GPU_THREAD_COUNT=8192
            log_message "  -> Using default GPU threads: $GPU_THREAD_COUNT"
        fi
    fi
fi

# --- Receptor Preparation ---
log_message "--------------------------------------------------"
log_message "Preparing receptor..."
log_message "  -> Adding H, calculating charges, and converting to PDBQT..."
# The -xr flag makes the receptor rigid for docking.
obabel -ipdb "$RECEPTOR_PDB_FILE" -opdbqt -O "$PREPARED_RECEPTOR_FILE" -xr -h &>> "$MAIN_LOG_FILE"
if [ $? -ne 0 ]; then
    log_message "  -> ERROR: Failed to prepare receptor. Check $MAIN_LOG_FILE for details."
    exit 1
fi
log_message "  -> Receptor preparation successful: ${PREPARED_RECEPTOR_FILE}"

# --- Create Vina Configuration File ---
log_message "Generating Vina configuration file: $CONFIG_FILE"

if [ "$USE_GPU" = "true" ]; then
    # Vina-GPU config format
    cat > "$CONFIG_FILE" <<EOL
# Vina-GPU Configuration (GPU-accelerated)
# Generated by Automated Docking Script - Dip Kumar Ghosh (Deon-07)
receptor = $PREPARED_RECEPTOR_FILE
center_x = $CENTER_X
center_y = $CENTER_Y
center_z = $CENTER_Z
size_x = $SIZE_X
size_y = $SIZE_Y
size_z = $SIZE_Z
thread = $GPU_THREAD_COUNT
EOL
    log_message "  -> GPU mode enabled with $GPU_THREAD_COUNT threads"
else
    # Standard Vina config format
    cat > "$CONFIG_FILE" <<EOL
# AutoDock Vina Configuration (CPU)
# Generated by Automated Docking Script - Dip Kumar Ghosh (Deon-07)
receptor = $PREPARED_RECEPTOR_FILE
center_x = $CENTER_X
center_y = $CENTER_Y
center_z = $CENTER_Z
size_x = $SIZE_X
size_y = $SIZE_Y
size_z = $SIZE_Z
num_modes = 9
exhaustiveness = 14
cpu = $THREADS_PER_JOB
EOL
    log_message "  -> CPU mode with $THREADS_PER_JOB threads per job"
fi

# --- Docking Function for GNU Parallel ---
# This function processes a single ligand and is called by GNU Parallel
dock_single_ligand() {
    local ligand_file="$1"
    
    # Skip if file doesn't exist
    [ -e "$ligand_file" ] || return 0
    
    local extension="${ligand_file##*.}"
    local ligand_basename=$(basename -- "$ligand_file" ."$extension")
    
    # Create unique identifier using relative path to avoid collisions
    # Example: ligands/groupA/drug1.sdf → groupA_drug1
    local abs_ligand_file=$(realpath "$ligand_file")
    local abs_ligand_dir=$(realpath "$LIGAND_DIR")
    local relative_path="${abs_ligand_file#$abs_ligand_dir/}"
    local relative_path_no_ext="${relative_path%.$extension}"
    # Replace directory separators with underscores for flat output structure
    local unique_id="${relative_path_no_ext//\//_}"
    
    # Create a dedicated directory for this ligand's results
    local ligand_result_dir="${VINA_OUTPUT_DIR}/${unique_id}"
    local poses_dir="${ligand_result_dir}/poses"
    
    # --- CHECKPOINTING: Skip if already processed ---
    if [ -d "$poses_dir" ] && [ -n "$(ls -A "$poses_dir" 2>/dev/null)" ]; then
        echo "[CHECKPOINT] Skipping $unique_id - already docked"
        return 0
    fi
    
    mkdir -p "$ligand_result_dir"
    
    local prepared_ligand_pdbqt="${PREPARED_LIGAND_DIR}/${unique_id}.pdbqt"
    local vina_out_file="${ligand_result_dir}/${unique_id}_out.pdbqt"
    local vina_log_file="${ligand_result_dir}/${unique_id}_log.txt"
    
    echo "[DOCKING] Processing: $unique_id"
    
    # 1. Prepare Ligand
    if ! obabel -i"$extension" "$ligand_file" -opdbqt -O "$prepared_ligand_pdbqt" -h 2>/dev/null; then
        echo "[ERROR] Failed to convert $unique_id. Skipping."
        return 1
    fi
    
    # 2. Run Docking (GPU or CPU mode)
    if [ "$USE_GPU" = "true" ]; then
        # Vina-GPU docking
        if ! "$VINA_GPU_EXECUTABLE" --config "$CONFIG_FILE" \
            --ligand "$prepared_ligand_pdbqt" \
            --out "$vina_out_file" 2>/dev/null; then
            echo "[ERROR] Vina-GPU docking failed for $unique_id."
            return 1
        fi
        # Create a simple log for GPU mode (Vina-GPU outputs to stdout)
        echo "GPU docking completed for $unique_id" > "$vina_log_file"
    else
        # Standard Vina CPU docking
        if ! "$VINA_EXECUTABLE" --config "$CONFIG_FILE" --ligand "$prepared_ligand_pdbqt" \
            --out "$vina_out_file" --log "$vina_log_file" --cpu "$THREADS_PER_JOB" 2>/dev/null; then
            echo "[ERROR] Vina docking failed for $unique_id."
            return 1
        fi
    fi
    
    # 3. Split poses and create PDB complexes
    mkdir -p "$poses_dir"
    
    # Run vina_split inside the ligand's result directory
    (
        cd "$ligand_result_dir" || exit
        "$VINA_SPLIT_EXECUTABLE" --input "${unique_id}_out.pdbqt" 2>/dev/null
    )
    
    # Loop through the split pose files to create complexes
    local pose_count=0
    for pose_pdbqt_file in "${ligand_result_dir}"/*_ligand_*.pdbqt; do
        [ -e "$pose_pdbqt_file" ] || continue
        
        pose_count=$((pose_count + 1))
        local pose_pdb_file="${poses_dir}/pose_${pose_count}_ligand.pdb"
        local complex_pdb_file="${poses_dir}/pose_${pose_count}_complex.pdb"
        
        # Convert PDBQT to PDB using obabel for proper format fidelity
        # This preserves element symbols and ensures valid PDB standards
        obabel -ipdbqt "$pose_pdbqt_file" -opdb -O "$pose_pdb_file" 2>/dev/null
        
        # Create complex: receptor + TER + ligand
        cat "$RECEPTOR_PDB_FILE" > "$complex_pdb_file"
        echo "TER" >> "$complex_pdb_file"
        cat "$pose_pdb_file" >> "$complex_pdb_file"
        
        # Clean up individual ligand PDB (keep only complex)
        rm "$pose_pdb_file" 2>/dev/null || true
    done
    
    # 4. Clean up intermediate files
    rm "${ligand_result_dir}"/*_ligand_*.pdbqt 2>/dev/null || true
    rm "$vina_out_file" 2>/dev/null || true
    
    echo "[SUCCESS] $unique_id - ${pose_count} poses saved"
    return 0
}

# Export function and variables for GNU Parallel
export -f dock_single_ligand
export VINA_OUTPUT_DIR PREPARED_LIGAND_DIR VINA_EXECUTABLE VINA_SPLIT_EXECUTABLE
export CONFIG_FILE RECEPTOR_PDB_FILE THREADS_PER_JOB LIGAND_DIR
export USE_GPU VINA_GPU_EXECUTABLE

# --- Ligand Preparation and Docking (Parallel) ---
log_message "--------------------------------------------------"

# Determine effective parallelism based on GPU/CPU mode
if [ "$USE_GPU" = "true" ]; then
    # Allow user to override concurrent jobs for GPU mode (e.g., 4 jobs on an A100)
    # Default to 4 if not specified, but warn about VRAM
    EFFECTIVE_JOBS="${CONCURRENT_JOBS:-4}"
    
    log_message "Starting GPU-accelerated docking (Vina-GPU)..."
    log_message "  -> Mode: GPU (CUDA)"
    log_message "  -> Concurrent jobs: $EFFECTIVE_JOBS (Warning: Monitor VRAM usage!)"
    log_message "  -> GPU threads per job: $GPU_THREAD_COUNT"
else
    EFFECTIVE_JOBS="$CONCURRENT_JOBS"
    log_message "Starting CPU parallel docking process..."
    log_message "  -> Mode: CPU"
    log_message "  -> Concurrent jobs: $CONCURRENT_JOBS"
    log_message "  -> Threads per job: $THREADS_PER_JOB"
fi

# Count ligand files
ligand_count=$(find "$LIGAND_DIR" \( -name "*.sdf" -o -name "*.mol2" \) -type f 2>/dev/null | wc -l)
log_message "Found $ligand_count ligand files to process"

# Run docking using GNU Parallel
log_message "--------------------------------------------------"
log_message "Launching docking with $EFFECTIVE_JOBS concurrent job(s)..."

find "$LIGAND_DIR" \( -name "*.sdf" -o -name "*.mol2" \) -type f | \
    parallel --jobs "$EFFECTIVE_JOBS" \
             --progress \
             --joblog "${MAIN_OUTPUT_DIR}/parallel_jobs.log" \
             dock_single_ligand {} 2>&1 | tee -a "$MAIN_LOG_FILE"

log_message "--------------------------------------------------"
log_message "Docking completed."

# --- Check for Failed Jobs ---
JOBLOG_FILE="${MAIN_OUTPUT_DIR}/parallel_jobs.log"
if [ -f "$JOBLOG_FILE" ]; then
    # Count failed jobs (exit code != 0, skip header line)
    FAILED_COUNT=$(awk 'NR>1 && $7!=0 {count++} END {print count+0}' "$JOBLOG_FILE")
    TOTAL_JOBS=$(awk 'NR>1 {count++} END {print count+0}' "$JOBLOG_FILE")
    SUCCESS_COUNT=$((TOTAL_JOBS - FAILED_COUNT))
    
    log_message "Job Summary: $SUCCESS_COUNT succeeded, $FAILED_COUNT failed out of $TOTAL_JOBS total"
    
    if [ "$FAILED_COUNT" -gt 0 ]; then
        log_message ""
        log_message "WARNING: $FAILED_COUNT job(s) failed! Failed ligands:"
        awk 'NR>1 && $7!=0 {for(i=9;i<=NF;i++) printf "%s ", $i; print ""}' "$JOBLOG_FILE" | while read -r failed_cmd; do
            log_message "  -> $failed_cmd"
        done
        log_message "Full job log: $JOBLOG_FILE"
    fi
fi

# --- Summarize Best Results ---
log_message "--------------------------------------------------"
log_message "Summarizing docking results..."

# Initialize CSV file with headers
CSV_FILE="${MAIN_OUTPUT_DIR}/summary_results.csv"
echo "Ligand_ID,Mode,Affinity_(kcal/mol),Dist_from_RMSD_lb,Dist_from_RMSD_ub" > "$CSV_FILE"
log_message "Generating CSV report: $CSV_FILE"

# Create a temporary file to hold all best scores
temp_scores_file="${MAIN_OUTPUT_DIR}/all_best_scores.tmp"
touch "$temp_scores_file"

# Use find to locate all individual log files recursively and extract the best score (mode 1)
for log_file in $(find "${VINA_OUTPUT_DIR}" -type f -name "*_log.txt"); do
    if [ -f "$log_file" ];
    then
        ligand_name=$(basename "$(dirname "$log_file")")
        
        # 1. Extract ALL modes to CSV
        awk -v name="$ligand_name" '
            /^[ \t]*[0-9]+/ {
                # Match lines starting with a number (the mode)
                # Output: Ligand, Mode, Affinity, RMSD_lb, RMSD_ub
                print name "," $1 "," $2 "," $3 "," $4
            }
        ' "$log_file" >> "$CSV_FILE"

        # 2. Extract best score only for console summary (Mode 1)
        grep -E "^ +1 " "$log_file" | awk -v name="$ligand_name" '{print name, $2}' >> "$temp_scores_file"
    fi
done

# Sort the temporary file by the second column (the score) and get the top 5
if [ -s "$temp_scores_file" ]; then
    log_message "Top 5 Docking Results (by Binding Affinity):"
    
    sort -k2 -n "$temp_scores_file" | head -n 5 | while read -r ligand_name affinity; do
        log_message "  -> Ligand: ${ligand_name}    Affinity: ${affinity} kcal/mol"
    done
else
    log_message "No docking results found to summarize."
fi

# Clean up the temporary file
rm "$temp_scores_file"

# --- Generate Combined SDF File ---
log_message "--------------------------------------------------"
log_message "Generating combined SDF file for all best poses..."
COMBINED_SDF="${MAIN_OUTPUT_DIR}/all_docked_hits.sdf"

# Find all best poses (pose_1) and convert to combined SDF
BEST_POSES=$(find "${VINA_OUTPUT_DIR}" -path "*/poses/pose_1_complex.pdb" -type f 2>/dev/null)
if [ -n "$BEST_POSES" ]; then
    echo "$BEST_POSES" | xargs obabel -ipdb -osdf -O "$COMBINED_SDF" 2>/dev/null
    COMPOUND_COUNT=$(grep -c '^\$\$\$\$' "$COMBINED_SDF" 2>/dev/null || echo "0")
    log_message "  -> Combined SDF: $COMBINED_SDF ($COMPOUND_COUNT compounds)"
else
    log_message "  -> No poses found to combine into SDF."
fi

# --- Generate Visualization Reports ---
log_message "--------------------------------------------------"
log_message "Generating visualization reports..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Phase 2: Histogram Generation (requires Python + pandas + matplotlib)
if command -v python3 &>/dev/null; then
    if python3 -c "import pandas; import matplotlib" 2>/dev/null; then
        HISTOGRAM_FILE="${MAIN_OUTPUT_DIR}/scores_histogram.png"
        if python3 "${SCRIPT_DIR}/plot_results.py" "$CSV_FILE" "$HISTOGRAM_FILE" -8.0 2>/dev/null; then
            log_message "  -> Histogram: $HISTOGRAM_FILE"
        else
            log_message "  -> WARNING: Histogram generation failed."
        fi
    else
        log_message "  -> Skipping histogram (missing: pip install pandas matplotlib)"
    fi
else
    log_message "  -> Skipping histogram (Python3 not found)"
fi

# --- SCRIPT END ---
end_time=$(date +%s)
runtime=$((end_time - start_time))

log_message "--------------------------------------------------"
log_message "Docking process completed for all ligands."
log_message "All results saved in: ${MAIN_OUTPUT_DIR}"
log_message "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."
log_message ""
log_message "=== Script finished successfully ==="
log_message "For issues and contributions, visit: https://github.com/Deon-07/automated-docking"