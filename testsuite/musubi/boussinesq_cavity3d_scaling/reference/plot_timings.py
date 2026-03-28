#!/usr/bin/env python3
"""
Plot Check and DoComp performance metrics from timeinfo files.

This script reads 'timeinfo' files located in directories named '*_nodes',
extracts the min, max, and sum timings for 'Check' and 'DoComp', calculates
the average (sum/nProc), and plots the results on a log-log scale.

Usage:
    python plot_timings.py --root . --timeinfo timeinfo --out scaling_plot.png
"""

# =========================
# Imports
# =========================
import argparse
import re
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

# =========================
# Data Parsing
# =========================
def parse_timeinfo(file_path):
    """
    Parses a single timeinfo file.
    Returns a dictionary with nProc and timing data for Check/DoComp.
    """
    data = {'Check': None, 'DoComp': None}
    n_proc = None
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
            
        for line in lines:
            # 1. Extract nProc from the headline
            # Example: " Timings for a run on          192 processes"
            if "processes" in line and n_proc is None:
                match = re.search(r'(\d+)\s+processes', line)
                if match:
                    n_proc = int(match.group(1))

            # 2. Extract timing rows
            parts = line.split()
            if not parts:
                continue

            timer_name = parts[0]
            if timer_name in ['Check', 'DoComp']:
                # Format: Name min max sum
                # Example: Check    69.134785E-03   222.711280E-03    25.379602E+00
                try:
                    t_min = float(parts[1])
                    t_max = float(parts[2])
                    t_sum = float(parts[3])
                    
                    if n_proc:
                        t_avg = t_sum / n_proc
                        data[timer_name] = {
                            'min': t_min,
                            'max': t_max,
                            'avg': t_avg
                        }
                except (ValueError, IndexError):
                    print(f"Warning: Could not parse line for {timer_name} in {file_path}")
                    continue
                    
        return n_proc, data
        
    except FileNotFoundError:
        print(f"Error: File {file_path} not found.")
        return None, None

# =========================
# Main Execution
# =========================
def main():
    # 1. Argument Parsing
    parser = argparse.ArgumentParser(
        description="Plot min/max/avg timing vs nodes from timeinfo files."
    )
    parser.add_argument(
        "--root", 
        type=str, 
        default=".", 
        help="Root directory containing the *_nodes subdirectories (default: current dir)."
    )
    parser.add_argument(
        "--timeinfo", 
        type=str, 
        default="timeinfo", 
        help="Name of the timeinfo file to look for in each *_nodes subdirectory (default: timeinfo)."
    )
    parser.add_argument(
        "--out", 
        type=str, 
        default="timing_plot.png", 
        help="Output filename for the plot (default: timing_plot.png)."
    )
    
    args = parser.parse_args()
    root_path = Path(args.root)

    # 2. Data Collection
    print(f"Scanning for data in {root_path} ...")
    
    # List to store (nodes, Check_data, DoComp_data)
    results = []
    
    # Search for directories matching *_nodes
    for node_dir in root_path.glob("*_nodes"):
        if not node_dir.is_dir():
            continue
            
        # Parse 'k' from folder name "k_nodes" to get node count 2^k
        try:
            folder_name = node_dir.name
            k_val = int(folder_name.split('_')[0])
            nodes = 2 ** k_val
        except ValueError:
            print(f"Skipping directory {node_dir.name}: does not match format 'INT_nodes'")
            continue
            
        # Look for timeinfo file inside
        timeinfo_path = node_dir / args.timeinfo
        if not timeinfo_path.exists():
            print(f"Skipping {node_dir.name}: timeinfo file missing.")
            continue
            
        # Parse file
        n_proc, timing_data = parse_timeinfo(timeinfo_path)
        
        if timing_data['Check'] and timing_data['DoComp']:
            results.append({
                'nodes': nodes,
                'Check': timing_data['Check'],
                'DoComp': timing_data['DoComp']
            })
    
    if not results:
        print("No valid data found. Exiting.")
        sys.exit(1)
        
    # Sort by number of nodes
    results.sort(key=lambda x: x['nodes'])
    
    # 3. Data Preparation for Plotting
    nodes_x = [r['nodes'] for r in results]
    
    # Helper to extract arrays for plotting
    def get_arrays(timer_key):
        avgs = np.array([r[timer_key]['avg'] for r in results])
        mins = np.array([r[timer_key]['min'] for r in results])
        maxs = np.array([r[timer_key]['max'] for r in results])
        
        # Calculate error bars relative to the average
        # yerr format: [lower_errors, upper_errors]
        lower_err = avgs - mins
        upper_err = maxs - avgs
        yerr = [lower_err, upper_err]
        
        return avgs, yerr

    check_avg, check_err = get_arrays('Check')
    docomp_avg, docomp_err = get_arrays('DoComp')

    # 4. Plotting
    print(f"Plotting results for {len(results)} data points...")
    
    fig, ax = plt.subplots(figsize=(10, 7))
    
    # Plot Check
    ax.errorbar(
        nodes_x, check_avg, yerr=check_err, 
        fmt='-o', capsize=5, linewidth=2, markersize=6,
        label='Check (Avg with Total time)'
    )
    
    # Plot DoComp
    ax.errorbar(
        nodes_x, docomp_avg, yerr=docomp_err, 
        fmt='-s', capsize=5, linewidth=2, markersize=6,
        label='DoComp (Avg with Total time)'
    )
    
    # Formatting axes
    ax.set_xscale('log', base=2)
    ax.set_yscale('log', base=2)
    
    ax.set_xlabel('Number of Nodes ($2^k$)', fontsize=12)
    ax.set_ylabel('Time (s)', fontsize=12)
    ax.set_title('Performance Scaling: Check vs DoComp', fontsize=14)
    
    # Grid and Legend
    ax.grid(True, which="major", ls="-", alpha=0.6)
    ax.grid(True, which="minor", ls=":", alpha=0.3)
    ax.legend(fontsize=11)
    
    # Save output
    plt.tight_layout()
    plt.savefig(args.out, dpi=300)
    print(f"Success! Plot saved to {args.out}")

if __name__ == "__main__":
    main()