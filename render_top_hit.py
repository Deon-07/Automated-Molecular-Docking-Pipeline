#!/usr/bin/env python3
"""
PyMOL 3D Rendering Script for Top Docking Hit
Generates a publication-quality image of receptor-ligand complex.

Usage: pymol -cq render_top_hit.py -- <receptor.pdb> <ligand_complex.pdb> <output.png>
"""

import sys
import os

# Parse command line arguments (after --)
args = sys.argv[1:]
if len(args) < 3:
    print("Usage: pymol -cq render_top_hit.py -- <receptor.pdb> <ligand.pdb> <output.png>")
    sys.exit(1)

receptor_file = args[0]
ligand_file = args[1]
output_file = args[2]

# PyMOL commands
from pymol import cmd

# Load structures
cmd.load(receptor_file, "receptor")
cmd.load(ligand_file, "ligand")

# Style receptor - white surface
cmd.hide("everything", "receptor")
cmd.show("surface", "receptor")
cmd.color("white", "receptor")
cmd.set("surface_color", "white", "receptor")
cmd.set("transparency", 0.3, "receptor")

# Style ligand - colored sticks
cmd.hide("everything", "ligand")
cmd.show("sticks", "ligand")
cmd.color("cyan", "ligand and elem C")
cmd.color("red", "ligand and elem O")
cmd.color("blue", "ligand and elem N")
cmd.color("yellow", "ligand and elem S")
cmd.set("stick_radius", 0.25, "ligand")

# Zoom on ligand with some padding
cmd.zoom("ligand", buffer=8)

# Set up nice rendering
cmd.set("ray_opaque_background", 0)  # Transparent background
cmd.set("antialias", 2)
cmd.set("ray_shadows", 1)
cmd.set("depth_cue", 0)
cmd.set("spec_reflect", 0.5)
cmd.set("ray_trace_mode", 1)

# Set viewport size
cmd.viewport(1920, 1080)

# Render and save
cmd.png(output_file, width=1920, height=1080, dpi=300, ray=1)

print(f"3D render saved: {output_file}")
cmd.quit()
