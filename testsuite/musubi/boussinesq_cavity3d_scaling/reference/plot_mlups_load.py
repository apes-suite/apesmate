#!/usr/bin/env python3
"""
Plot MLUPs per node vs elements per node from an APES timing result file.

Usage:
    python plot_mlups_load.py --timing timing_apes.res --base 192 --out mlups_load.png
"""

import argparse
import math
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

import gleaner


# Hard-coded elements per node

ELEMENTS_PER_NODE = [
    512,
    4096,
    32768,
    262144,
    2097152,
    16777216,
]

markers = ["o", "s", "^", "D", "v", ">", "<", "P", "X", "*", "+"]


def compute_index(nprocs, base=192):
    """
    Index such that nprocs = base * 2^i.
    """
    return math.log2(nprocs / base)

def find_closest_value(value, candidates):
    """
    Find the closest value in candidates list to the given value.
    """
    return min(candidates, key=lambda x: abs(x - value))


def read_timing_data(timing_path: Path, base: int):
    """
    Read the timing file and return list entries for plotting.
    """
    data_points = []  # list of dicts: {i, elem, mlups_over_i}
    counters = {}     # i -> how many times we've seen this i
    df = gleaner.load_timing_dataframe(timing_path)

    for row in df.itertuples(index=False):
        try:
            nprocs = int(row.nProcs)
            mlups = float(row.MLUPs)
        except (AttributeError, TypeError, ValueError):
            continue

        i_float = compute_index(nprocs, base=base)
        i = int(round(i_float))

        if base * (2 ** i) != nprocs:
            continue

        j = counters.get(i, 0)
        counters[i] = j + 1
        if j >= len(ELEMENTS_PER_NODE):
            continue

        elem = ELEMENTS_PER_NODE[j] * 2

        data_points.append(
            {"i": i, "elem": elem, "mlups": mlups}
        )

    return data_points


def plot_speedup_efficiency(data_points, outfile: Path | None = None):
    """
    Plot mlups/i vs elements per node.
    """
    # group by nodes
    by_nodes = {}
    for dp in data_points:
        nodes = 2 ** dp["i"]
        by_nodes.setdefault(nodes, {"elem": [], "mlups_over_i": []})
        by_nodes[nodes]["elem"].append(dp["elem"])
        by_nodes[nodes]["mlups_over_i"].append(dp["mlups"] / (2**dp["i"]))


    fig, ax_mlups = plt.subplots(figsize=(8, 6))
    
    for cnt, i in enumerate(sorted(by_nodes.keys())):
        xs = by_nodes[i]["elem"]
        ys = by_nodes[i]["mlups_over_i"]

        marker = markers[cnt % len(markers)]

        ax_mlups.plot(
            xs, ys, marker=marker,
            label=f"nodes = {i}"
        )
    
    # ---------- axes formatting ----------
    ax_mlups.set_xscale("log", base=2)
    ax_mlups.xaxis.set_major_formatter(
        mticker.FuncFormatter(lambda x, pos: f"{int(x)}")
    )
    ax_mlups.grid(True, which="both", linestyle="--", alpha=0.5)
        
    # labels
    ax_mlups.set_ylabel("MLUPs per Node")
    ax_mlups.set_xlabel("Elements per Node")

    # legends (only once, cleaner)
    ax_mlups.legend(ncol=2, fontsize=9)

    plt.tight_layout()

    if outfile is not None:
        plt.savefig(outfile, dpi=200)
        print(f"Saved figure to {outfile}")
    else:
        plt.show()

def main():
    parser = argparse.ArgumentParser(
        description="Plot MLUPs per node vs elements per node from an APES timing file"
    )
    parser.add_argument(
        "--timing", required=True, help="Path to the APES timing result file"
    )
    parser.add_argument(
        "--base",
        type=int,
        default=192,
        help="Base processor count for index i (default: 192, so nProcs = base * 2^i)",
    )
    parser.add_argument(
        "--out",
        type=str,
        default="speedup_efficiency.png",
        help="Output PNG filename (default: speedup_efficiency.png)",
    )

    args = parser.parse_args()

    timing_path = Path(args.timing)
    data_points = read_timing_data(timing_path, base=args.base)

    if not data_points:
        print("No data points extracted. Check timing file and base setting.")
        return

    plot_speedup_efficiency(data_points, outfile=Path(args.out))


if __name__ == "__main__":
    main()
