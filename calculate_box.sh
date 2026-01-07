#!/bin/bash
# =============================================================================
# Auto-Calculate Docking Box from PDB Receptor
# =============================================================================
# This script calculates the center and size of a docking box based on the
# coordinates of a PDB receptor file. Optionally adds padding to the box.
#
# Usage: ./calculate_box.sh <receptor.pdb> [padding]
#   receptor.pdb  - Path to the receptor PDB file
#   padding       - Optional padding in Angstroms (default: 10)
#
# Output: Prints the docking box parameters suitable for docking.conf
# =============================================================================

set -e

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <receptor.pdb> [padding] [fixed_size]" >&2
    echo "  receptor.pdb  - Path to the receptor PDB file" >&2
    echo "  padding       - Optional padding in Angstroms (default: 10). Ignored if fixed_size is set." >&2
    echo "  fixed_size    - Optional fixed box size (e.g., 20) for GPU safety." >&2
    exit 1
fi

PDB_FILE="$1"
PADDING="${2:-10}"
FIXED_SIZE="${3:-0}"

# Validate file exists
if [ ! -f "$PDB_FILE" ]; then
    echo "ERROR: PDB file not found: $PDB_FILE" >&2
    exit 1
fi

# Extract ATOM/HETATM coordinates and calculate box
awk -v padding="$PADDING" '
BEGIN {
    minx = 9999; miny = 9999; minz = 9999
    maxx = -9999; maxy = -9999; maxz = -9999
    count = 0
}
/^ATOM|^HETATM/ {
    x = substr($0, 31, 8) + 0
    y = substr($0, 39, 8) + 0
    z = substr($0, 47, 8) + 0
    
    if (x < minx) minx = x
    if (y < miny) miny = y
    if (z < minz) minz = z
    if (x > maxx) maxx = x
    if (y > maxy) maxy = y
    if (z > maxz) maxz = z
    count++
}
END {
    if (count == 0) {
        print "ERROR: No ATOM/HETATM records found in PDB file" > "/dev/stderr"
        exit 1
    }
    
    # Calculate center
    cx = (minx + maxx) / 2
    cy = (miny + maxy) / 2
    cz = (minz + maxz) / 2
    
    # Calculate size
    if (fixed_size > 0) {
        # Use fixed size if provided (safe for GPU)
        sx = fixed_size
        sy = fixed_size
        sz = fixed_size
        padding_note = "Fixed size (GPU safe)"
    } else {
        # Calculate size based on protein dimensions + padding
        sx = (maxx - minx) + padding
        sy = (maxy - miny) + padding
        sz = (maxz - minz) + padding
        padding_note = padding " Angstroms"
    }
    
    # Print results
    printf "# Auto-calculated from: %s\n", FILENAME
    printf "# Atoms processed: %d\n", count
    printf "# Box Sizing: %s\n", padding_note
    printf "CENTER_X=\"%.2f\"\n", cx
    printf "CENTER_Y=\"%.2f\"\n", cy
    printf "CENTER_Z=\"%.2f\"\n", cz
    printf "SIZE_X=\"%.2f\"\n", sx
    printf "SIZE_Y=\"%.2f\"\n", sy
    printf "SIZE_Z=\"%.2f\"\n", sz
}
' -v fixed_size="$FIXED_SIZE" "$PDB_FILE"
