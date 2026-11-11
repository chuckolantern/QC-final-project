"""One Aer circuit with snapshots: no quadratic prefix reruns."""

from dataclasses import dataclass
import numpy as np
from qiskit import transpile
from qiskit.quantum_info import DensityMatrix, Pauli, partial_trace
from qiskit_aer import AerSimulator
from .config import Config
from .model import append_step, preparation


@dataclass
class Result:
    times_h: np.ndarray
    density_matrices: np.ndarray
    bloch: np.ndarray  # (time, [SCN, liver], [X,Y,Z])
    purity: np.ndarray  # full two-qubit purity
    min_eigenvalue: np.ndarray
    trace_error: np.ndarray
    hermiticity_error: np.ndarray
    circuit_depth: int
    integration_steps: int


def time_grid(duration: float, output_step: float) -> np.ndarray:
    count = int(np.floor(duration / output_step))
    times = np.arange(count + 1, dtype=float) * output_step
    tolerance = 1e-12 * max(1, duration)
    if abs(times[-1] - duration) <= tolerance:
        times[-1] = duration
    else:
        times = np.append(times, duration)
    return times


def build_circuit(config: Config):
    times = time_grid(config.simulation.duration_h, config.simulation.output_step_h)
    circuit = preparation(config.initial)
    circuit.save_density_matrix(label="rho_0")
    steps = 0
    for index in range(1, len(times)):
        interval = times[index] - times[index - 1]
        count = max(1, int(np.ceil(interval / config.simulation.max_step_h - 1e-12)))
        for _ in range(count):
            append_step(circuit, config.model, interval / count)
        steps += count
        circuit.save_density_matrix(label=f"rho_{index}")
    return circuit, times, steps


def simulate(config: Config) -> Result:
    circuit, times, steps = build_circuit(config)
    backend = AerSimulator(method="density_matrix", device="CPU", max_parallel_threads=1)
    compiled = transpile(circuit, backend, optimization_level=0, seed_transpiler=config.simulation.seed)
    job_result = backend.run(compiled, shots=1, seed_simulator=config.simulation.seed).result()
    if not job_result.success:
        raise RuntimeError(str(job_result.status))
    snapshots = job_result.data(0)
    matrices = np.stack([np.asarray(snapshots[f"rho_{i}"]) for i in range(len(times))])
    bloch = np.empty((len(times), 2, 3))
    for index, matrix in enumerate(matrices):
        rho = DensityMatrix(matrix)
        for qubit in (0, 1):
            reduced = partial_trace(rho, [1 - qubit])
            bloch[index, qubit] = [reduced.expectation_value(Pauli(axis)).real for axis in "XYZ"]
    trace_error = np.abs(np.trace(matrices, axis1=1, axis2=2) - 1)
    hermiticity_error = np.max(np.abs(matrices - matrices.conj().transpose(0, 2, 1)), axis=(1, 2))
    eigenvalues = np.linalg.eigvalsh(matrices)
    purity = np.einsum("tij,tji->t", matrices, matrices).real
    if max(trace_error.max(), hermiticity_error.max(), -eigenvalues.min()) > 1e-8:
        raise RuntimeError("Invalid simulated density matrix")
    return Result(times, matrices, bloch, purity, eigenvalues[:, 0], trace_error,
                  hermiticity_error, compiled.depth(), steps)
