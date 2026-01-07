#!/usr/bin/env python3
import sys
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np

def plot_histogram(csv_file, output_file, threshold):
    try:
        # Load data
        df = pd.read_csv(csv_file)
        
        # Check if empty or only headers
        if df.empty or len(df) == 0:
            print("WARNING: No data in CSV to plot.")
            return

        # Filter for Mode 1 (best pose)
        best_poses = df[df['Mode'] == 1].copy()
        
        if best_poses.empty:
            print("WARNING: No Mode 1 poses found.")
            return

        scores = best_poses['Affinity_(kcal/mol)']
        
        # Setup aesthetic style
        plt.style.use('bmh') # 'bmh' is a nice built-in style
        
        # --- Plot 1: Histogram ---
        fig1, ax1 = plt.subplots(figsize=(10, 7), dpi=150)
        
        # Colors
        main_color = '#2c3e50'
        highlight_color = '#e74c3c'
        bar_color = '#3498db'
        
        # Plot Histogram
        n, bins, patches = ax1.hist(scores, bins=20, color=bar_color, alpha=0.75, 
                                 edgecolor='white', linewidth=1, label='Docking Scores')
        
        # Calculate statistics
        mean_score = scores.mean()
        min_score = scores.min()
        max_score = scores.max()
        count = len(scores)
        hits = scores[scores <= threshold]
        hit_count = len(hits)
        hit_percentage = (hit_count / count) * 100
        
        # Add threshold line
        ax1.axvline(threshold, color=highlight_color, linestyle='--', linewidth=2, 
                 label=f'Hit Threshold ({threshold} kcal/mol)')
        
        # Add best score line
        ax1.axvline(min_score, color='#27ae60', linestyle='-', linewidth=2, 
                 label=f'Best Score ({min_score} kcal/mol)')

        # Labels for Histogram
        ax1.set_xlabel('Binding Affinity (kcal/mol)', fontsize=12, fontweight='bold')
        ax1.set_ylabel('Frequency', fontsize=12, fontweight='bold')
        ax1.set_title('Distribution of Docking Scores', fontsize=16, fontweight='bold')
        ax1.legend(loc='upper right')
        ax1.grid(True, linestyle=':', alpha=0.6)
        
        # Stats box
        stats_text = (
            f"Total Compounds: {count}\n"
            f"Hits (≤ {threshold}): {hit_count} ({hit_percentage:.1f}%)\n"
            f"Best Score: {min_score:.2f} kcal/mol\n"
            f"Mean Score: {mean_score:.2f} kcal/mol"
        )
        props = dict(boxstyle='round', facecolor='wheat', alpha=0.5)
        ax1.text(0.02, 0.95, stats_text, transform=ax1.transAxes, fontsize=10,
                verticalalignment='top', bbox=props)
        
        plt.tight_layout()
        plt.savefig(output_file)
        plt.close(fig1)
        print(f"Histogram saved as: {output_file}")

        # --- Plot 2: Bar Chart ---
        # Derive output filename for bar chart (e.g. histogram.png -> histogram_barchart.png)
        if '.' in output_file:
            base, ext = output_file.rsplit('.', 1)
            bar_output_file = f"{base}_barchart.{ext}"
        else:
            bar_output_file = f"{output_file}_barchart"

        fig2, ax2 = plt.subplots(figsize=(12, 8), dpi=150)
        
        # Sort by score for better visualization
        best_poses_sorted = best_poses.sort_values('Affinity_(kcal/mol)', ascending=True) # Best (most negative) first
        
        # Create Bar Plot
        ligands = best_poses_sorted['Ligand_ID']
        affinities = best_poses_sorted['Affinity_(kcal/mol)']
        
        # Color bars based on threshold
        colors = [highlight_color if x <= threshold else bar_color for x in affinities]
        
        bars = ax2.bar(ligands, affinities, color=colors, alpha=0.8, edgecolor='black', linewidth=0.5)
        
        # Add threshold line to bar chart
        ax2.axhline(threshold, color='red', linestyle='--', linewidth=1.5, label=f'Threshold ({threshold})')
        
        # customization
        ax2.set_ylabel('Binding Affinity (kcal/mol)', fontsize=12, fontweight='bold')
        ax2.set_xlabel('Ligand ID', fontsize=12, fontweight='bold')
        ax2.set_title('Docking Scores per Ligand (Sorted)', fontsize=14, fontweight='bold')
        
        # Rotate x-labels if many ligands
        if len(ligands) > 10:
            ax2.set_xticklabels(ligands, rotation=45, ha='right', fontsize=8)
        else:
            ax2.set_xticklabels(ligands, rotation=0, fontsize=10)
            
        ax2.grid(True, axis='y', linestyle=':', alpha=0.6)
        
        # Layout adjustment
        plt.tight_layout()
        
        # Save
        plt.savefig(bar_output_file)
        plt.close(fig2)
        print(f"Bar chart saved as: {bar_output_file}")
        
    except Exception as e:
        print(f"Error generating plot: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: plot_results.py <csv_file> <output_image> <threshold>")
        sys.exit(1)
        
    csv_path = sys.argv[1]
    img_path = sys.argv[2]
    
    try:
        threshold_val = float(sys.argv[3])
    except ValueError:
        threshold_val = -8.0
        
    plot_histogram(csv_path, img_path, threshold_val)
