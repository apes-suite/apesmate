#!/usr/bin/env python3
"""
Helpers for reading timing result files with header extraction and pandas.
"""

from io import StringIO
from pathlib import Path

import pandas as pd


def expand_header_tokens(raw_header_line: str):
    """Expand whitespace-separated header tokens and split combined entries."""
    logical_headers = []
    for raw_token in raw_header_line.split():
        for token in raw_token.split("|"):
            token = token.strip()
            if token:
                logical_headers.append(token)
    return logical_headers


def read_header(filename: Path):
    """Extract logical column names from the first header line."""
    try:
        with filename.open("r", encoding="utf-8") as handle:
            for line in handle:
                stripped = line.strip()
                if stripped.startswith("#"):
                    return expand_header_tokens(stripped.lstrip("#").strip())
    except FileNotFoundError as exc:
        raise FileNotFoundError(f"Could not find file: {filename}") from exc

    raise ValueError(f"Could not find a header line in {filename}")


def load_timing_dataframe(filename: Path) -> pd.DataFrame:
    """Load timing data rows into a DataFrame using the extracted header."""
    header_names = read_header(filename)

    df = pd.read_csv(
        filename,
        sep=r"\s+",
        engine="python",
        comment="#",
        header=None
    )

    if df.shape[1] != len(header_names):
        raise ValueError(
            f"Header/data column mismatch in {filename}: "
            f"{len(header_names)} headers, {df.shape[1]} data columns"
        )

    df.columns = header_names
    return df
