#!/usr/bin/env python3
"""
Plot speedup and efficiency vs nodes from timing_apes_ref.res.

Usage:
    python plot_speedup_eff.py --timing timing_apes_ref.res --base 192 --out apes_speedup_efficiency.png
"""

import argparse
import math
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker


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


def expand_header_tokens(raw_header_line: str):
    """
    Take the raw header line (without leading '#') and expand tokens that
    contain multiple names separated by '|' into separate logical columns.

    Example:
        'fillStFun|init_cplComm|' -> ['fillStFun', 'init_cplComm']
        'evalVal|dom_fluidWai|dom_fluidSin|dom_fluidEva|' ->
            ['evalVal', 'dom_fluidWai', 'dom_fluidSin', 'dom_fluidEva']
    """
    raw_tokens = raw_header_line.split()
    logical_headers = []
    for raw in raw_tokens:
        parts = raw.split("|")
        for p in parts:
            p = p.strip()
            if p:
                logical_headers.append(p)
    return logical_headers


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
    Read timing_apes_ref.res and return list of (i, elem_per_node, mlups/i).

    The j-th occurrence of a given i gets ELEMENTS_PER_NODE[j].
    """
    header = None
    data_points = []  # list of dicts: {i, elem, mlups_over_i}
    counters = {}     # i -> how many times we've seen this i

    with timing_path.open("r") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line.strip():
                continue

            # Header line
            if line.startswith("#"):
                raw_header = line.lstrip("#").strip()
                header = expand_header_tokens(raw_header)
                continue

            if header is None:
                continue  # skip until we see the header

            # Skip any comment/data we don't want
            if line.startswith("!"):
                continue

            parts = line.split()
            if len(parts) != len(header):
                # malformed line (or doesn't match expanded header)
                # you can print a warning here if needed
                continue

            row = dict(zip(header, parts))

            try:
                nprocs = int(row["nProcs"])
                mlups = float(row["MLUPs"])
            except (KeyError, ValueError):
                continue

            # compute i = log2(nprocs / base)
            i_float = compute_index(nprocs, base=base)
            i = int(round(i_float))

            # sanity check: should be exact power of two
            if base * (2 ** i) != nprocs:
                continue

            # j = occurrence index of this i
            j = counters.get(i, 0)
            counters[i] = j + 1

            elem = ELEMENTS_PER_NODE[j] * 2

            data_points.append(
                {"i": i, "elem": elem, "mlups": mlups}
            )

    return data_points


def plot_speedup_efficiency(data_points, outfile: Path | None = None):
    """
    Plot speed up and efficiency vs nNodes.
    """
    # group by i
    by_elem = {}
    for dp in data_points:
        elem = dp["elem"]
        by_elem.setdefault(elem, {"nodes": [], "mlups": []})
        by_elem[elem]["nodes"].append(2**dp["i"])
        by_elem[elem]["mlups"].append(dp["mlups"])  

    fig, (ax_speedup, ax_eff) = plt.subplots(
        2, 1, figsize=(7, 8), sharex=True
    )
    
    for cnt, i in enumerate(sorted(by_elem.keys())):
        xs = by_elem[i]["nodes"]
        ys = by_elem[i]["mlups"]

        # sort by nodes
        xs, ys = zip(*sorted(zip(xs, ys), key=lambda t: t[0]))

        # reference (smallest node count)
        x_ref = xs[0]
        y_ref = ys[0]

        # plot the reference lines
        if cnt == 0:
            # ideal weak-scaling references
            speedup_ref = [x / x_ref for x in xs]
            efficiency_ref = [1.0 for _ in xs]

            ax_speedup.plot(
                xs, speedup_ref,
                linestyle="--",
                color="k",
                linewidth=1.5,
                label="Ideal weak scaling"
            )

            ax_eff.plot(
                xs, efficiency_ref,
                linestyle="--",
                color="k",
                linewidth=1.5,
                label="Ideal efficiency"
            )

        # speedup and efficiency
        speedup = [y / y_ref for y in ys]
        efficiency = [
            s / (x / x_ref) for s, x in zip(speedup, xs)
        ]

        marker = markers[cnt % len(markers)]

        ax_speedup.plot(
            xs, speedup, marker=marker,
            label=f"elems_per_node = {i}"
        )
        ax_eff.plot(
            xs, efficiency, marker=marker,
            label=f"elems_per_node = {i}"
        )
    
    # ---------- axes formatting ----------
    for ax in (ax_speedup, ax_eff):
        ax.set_xscale("log", base=2)
        ax.xaxis.set_major_formatter(
            mticker.FuncFormatter(lambda x, pos: f"{int(x)}")
        )
        ax.grid(True, which="both", linestyle="--", alpha=0.5)
        
    # labels
    ax_speedup.set_yscale("log", base=2)
    ax_speedup.set_ylabel("Speedup")
    ax_eff.set_ylabel("Efficiency")
    ax_eff.set_xlabel("Nodes")

    # legends (only once, cleaner)
    ax_eff.legend(ncol=2, fontsize=9)

    plt.tight_layout()

    if outfile is not None:
        plt.savefig(outfile, dpi=200)
        print(f"Saved figure to {outfile}")
    else:
        plt.show()

def main():
    parser = argparse.ArgumentParser(
        description="Plot MLUPs / i vs elements per node from timing_apes_ref.res"
    )
    parser.add_argument(
        "--timing", required=True, help="Path to timing_apes_ref.res"
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
