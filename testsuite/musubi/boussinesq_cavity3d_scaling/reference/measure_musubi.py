#!/usr/bin/env python3
"""
Plot weak-scaling performance metrics of Musubi from timing output.

This script reconstructs *absolute time* (seconds)
for compute, communication, source, and auxiliary parts, and plots
diagonal weak-scaling curves (constant load per core).

Usage:
    python measure_musubi.py --timing timing_fluid.res --base 192 --out fluid_scaling.png
"""

# =========================
# Imports
# =========================
import argparse
from pathlib import Path

import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


# =========================
# Global configuration
# =========================
METRICS_MAP = [
    ("Abs_Comm",   "Communication Time"),
    ("Abs_Comp",   "Compute (Kernel) Time"),
    ("Abs_Source", "Source Term Time"),
    ("Abs_Aux",    "Auxiliary Time")
]


# =========================
# Functions
# =========================
def load_data(filename: Path) -> pd.DataFrame:
    """Load whitespace-separated timing data."""
    try:
        # df = pd.read_csv(filename, sep=r"\s+")
        df = pd.read_csv(
            filename,
            sep=r"\s+",          # split on arbitrary whitespace
            engine="python",     # robust parser
            comment="#",         # ignore header lines starting with #
            header=None          # we define headers manually
        )
    except FileNotFoundError:
        raise FileNotFoundError(f"Could not find file: {filename}")

    # Assign column names manually (based on file structure)
    df.columns = [
        "Revision",
        "SimName",
        "DomSize",
        "nProcs",
        "nThreads", # only exists when omp is enabled
        "MLUPs",
        "MLUPs_kernel",
        "imbalance_percent",
        "timeMusubi",
        "maxIter",
        "totalDens",
        "timeMainLoop",
        "timeLoadMesh",
        "timeInitLvlD",
        "timewRestart",
        "timeBalance",
        "timeSource",
        "timeCheck", # new feature
        "timeDoComp",
        "timeAux",
        "timeRelax",
        "Comp_percent",
        "Comm_percent",
        "BCbuffer_percent",
        "BC_percent",
        "Intp_percent",
    ]
    return df


def compute_absolute_metrics(df: pd.DataFrame) -> pd.DataFrame:
    """
    Convert raw timers and percentages into absolute seconds per iteration.
    """
    df = df.copy()

    # Direct timers
    df["Abs_Source"] = df["timeSource"]
    df["Abs_Aux"] = df["timeAux"]
    df["Abs_relax"] = df["timeRelax"]

    # Reconstructed from percentages
    df["Abs_Comp"] = (df["Comp_percent"] / 100.0) * (df["timeMainLoop"])
    df["Abs_Comm"] = (df["Comm_percent"] / 100.0) * (df["timeMainLoop"])

    # The sum-up of the 5 parts to the Mainloop time
    df["Sum_Percent"] = (
        df["Abs_Source"] + df["Abs_Aux"] + df["Abs_relax"] 
    ) / df["timeMainLoop"] * 100.0
    + df["BCbuffer_percent"] + df["BC_percent"] + df["Intp_percent"] + df["Comp_percent"] + df["Comm_percent"]

    return df


def build_diagonal_curves(df: pd.DataFrame, metric: str):
    """
    Build weak-scaling diagonal curves:
    nProcs[i] ↔ DomSize[i + offset]
    """
    curves = []

    n_procs_list = sorted(df["nProcs"].unique())
    dom_sizes_list = sorted(df["DomSize"].unique())

    min_offset = -2
    max_offset = len(dom_sizes_list) - len(n_procs_list) + 2

    for offset in range(min_offset, max_offset + 1):
        x_vals, y_vals = [], []
        load_per_core = None

        for i, n_proc in enumerate(n_procs_list):
            dom_idx = i + offset
            if 0 <= dom_idx < len(dom_sizes_list):
                d_size = dom_sizes_list[dom_idx]
                row = df[(df["nProcs"] == n_proc) & (df["DomSize"] == d_size)]

                if not row.empty:
                    x_vals.append(n_proc)
                    y_vals.append(row[metric].values[0])

                    if load_per_core is None:
                        load_per_core = int(d_size / n_proc)

        if len(x_vals) >= 2:
            curves.append((x_vals, y_vals, load_per_core))

    return curves


def plot_metrics(df: pd.DataFrame, base: int, outfile: Path):
    """Create 2×2 subplot figure for all metrics."""
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle(
        "Weak Scaling: Absolute Time (Diagonal Index Match)",
        fontsize=16,
    )

    for ax, (col_name, title) in zip(axes.flatten(), METRICS_MAP):
        ax.set_title(title)
        ax.set_xlabel(f"Number of Nodes (Base {base} Procs)")
        ax.set_ylabel("Seconds")
        ax.set_xscale("log", base=2)
        ax.set_yscale("log", base=2)

        curves = build_diagonal_curves(df, col_name)

        for x_vals, y_vals, load_per_core in curves:
            nodes_vals = [x // base for x in x_vals]
            ax.plot(nodes_vals, y_vals, marker="o", label=f"Load ~{load_per_core}")

        ax.grid(True, which="both", linestyle="-", alpha=0.4)

    axes[1, 1].legend(
        bbox_to_anchor=(1.05, 1), loc="upper left", title="Elements/Core"
    )

    plt.tight_layout()
    plt.savefig(outfile, dpi=300)
    print(f"Saved figure to {outfile}")


# =========================
# Main
# =========================
def main():
    parser = argparse.ArgumentParser(
        description="Plot Musubi weak-scaling performance metrics"
    )
    parser.add_argument(
        "--timing",
        required=True,
        help="Path to timing result file (whitespace-separated)",
    )
    parser.add_argument(
        "--base", 
        type=str, 
        default="192",
        help="Base number of processes for scaling (default: 192)."
    )
    parser.add_argument(
        "--out",
        default="musubi_scaling.png",
        help="Output figure filename",
    )

    args = parser.parse_args()

    timing_path = Path(args.timing)
    outfile = Path(args.out)

    df = load_data(timing_path)
    df = compute_absolute_metrics(df)
    plot_metrics(df, int(args.base), outfile)


if __name__ == "__main__":
    main()
