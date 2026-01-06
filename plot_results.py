#!/usr/bin/env python3
"""
Binding Affinity Distribution Plotter
Generates a histogram of docking scores with threshold line.

Usage: python3 plot_results.py <csv_file> <output_png> [threshold]
Example: python3 plot_results.py summary_results.csv affinity_distribution.png -8.0
"""

import sys
import os

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 plot_results.py <csv_file> <output_png> [threshold]")
        print("Example: python3 plot_results.py summary_results.csv output.png -8.0")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    output_file = sys.argv[2]
    threshold = float(sys.argv[3]) if len(sys.argv) > 3 else -8.0
    
    if not os.path.exists(csv_file):
        print(f"ERROR: CSV file not found: {csv_file}")
        sys.exit(1)
    
    try:
        import pandas as pd
        import matplotlib.pyplot as plt
        import matplotlib
        matplotlib.use('Agg')  # Non-interactive backend for servers
    except ImportError as e:
        print(f"ERROR: Missing dependency: {e}")
        print("Install with: pip install pandas matplotlib")
        sys.exit(1)
    
    # Read CSV and extract best scores (Mode 1 only)
    df = pd.read_csv(csv_file)
    best_scores = df[df['Mode'] == 1]['Affinity_(kcal/mol)'].dropna()
    
    if best_scores.empty:
        print("WARNING: No scores found in CSV file.")
        sys.exit(0)
    
    # Calculate statistics
    total_compounds = len(best_scores)
    hits_below_threshold = (best_scores <= threshold).sum()
    hit_rate = (hits_below_threshold / total_compounds) * 100
    
    # Create histogram
    fig, ax = plt.subplots(figsize=(10, 6))
    
    n, bins, patches = ax.hist(best_scores, bins=30, edgecolor='black', alpha=0.7, color='steelblue')
    
    # Color bars below threshold
    for i, patch in enumerate(patches):
        if bins[i] <= threshold:
            patch.set_facecolor('seagreen')
    
    # Add threshold line
    ax.axvline(x=threshold, color='red', linestyle='--', linewidth=2, 
               label=f'Threshold: {threshold} kcal/mol')
    
    # Labels and title
    ax.set_xlabel('Binding Affinity (kcal/mol)', fontsize=12)
    ax.set_ylabel('Number of Compounds', fontsize=12)
    ax.set_title('Distribution of Docking Scores', fontsize=14, fontweight='bold')
    
    # Add statistics box
    stats_text = f'Total Compounds: {total_compounds}\n'
    stats_text += f'Hits (≤ {threshold}): {hits_below_threshold} ({hit_rate:.1f}%)\n'
    stats_text += f'Best Score: {best_scores.min():.2f} kcal/mol'
    
    ax.text(0.02, 0.98, stats_text, transform=ax.transAxes, fontsize=10,
            verticalalignment='top', bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.8))
    
    ax.legend(loc='upper right')
    ax.grid(axis='y', alpha=0.3)
    
    # Save figure
    plt.tight_layout()
    plt.savefig(output_file, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"Histogram saved: {output_file}")
    print(f"  Total compounds: {total_compounds}")
    print(f"  Hits (≤ {threshold} kcal/mol): {hits_below_threshold} ({hit_rate:.1f}%)")

if __name__ == "__main__":
    main()
