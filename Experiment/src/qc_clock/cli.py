"""Reproducible run output: config, versions, CSV and complete density matrices."""

import argparse
import csv
from dataclasses import asdict
from importlib.metadata import version
import json
from pathlib import Path
import platform
import sys
import numpy as np
from .config import load_config
from .simulator import simulate


def main():
    parser = argparse.ArgumentParser(description="Qiskit H0 two-qubit baseline")
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True,
                        help="New run directory; existing directories are never overwritten")
    args = parser.parse_args()
    config = load_config(args.config)
    if args.output.exists():
        parser.error(f"Output already exists: {args.output}")
    result = simulate(config)
    args.output.mkdir(parents=True, exist_ok=False)
    np.savez_compressed(args.output / "states.npz", times_h=result.times_h,
                        density_matrices=result.density_matrices, bloch=result.bloch)
    with (args.output / "observables.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["time_h", "scn_x", "scn_y", "scn_z", "liver_x", "liver_y", "liver_z",
                         "global_purity", "min_eigenvalue", "trace_error", "hermiticity_error"])
        for i, time in enumerate(result.times_h):
            writer.writerow([time, *result.bloch[i].ravel(), result.purity[i], result.min_eigenvalue[i],
                             result.trace_error[i], result.hermiticity_error[i]])
    metadata = {
        "config": asdict(config), "source_config": str(args.config.resolve()),
        "python": sys.version, "platform": platform.platform(),
        "versions": {name: version(name) for name in ("qc-clock-model", "qiskit", "qiskit-aer", "numpy", "scipy")},
        "backend": "AerSimulator density_matrix CPU; exact expectations, no shot sampling",
        "integrator": "second-order Strang splitting of H0",
        "basis_order": "|q_liver q_scn>; SCN=Qiskit 0; liver=Qiskit 1",
        "integration_steps": result.integration_steps, "circuit_depth": result.circuit_depth,
        "max_trace_error": float(result.trace_error.max()),
        "max_hermiticity_error": float(result.hermiticity_error.max()),
        "min_eigenvalue": float(result.min_eigenvalue.min()),
    }
    (args.output / "metadata.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False), encoding="utf-8")
    message = f"Saved {len(result.times_h)} snapshots to {args.output.resolve()}"
    encoding = sys.stdout.encoding or "utf-8"
    print(message.encode(encoding, errors="backslashreplace").decode(encoding))


if __name__ == "__main__":
    main()
