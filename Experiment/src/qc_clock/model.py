"""Explicit mapping: plan q1 (SCN) = Qiskit 0; plan q2 (liver) = 1.

Qiskit matrices use |q_liver q_scn>, so SCN Y is IY, not YI.
"""

import numpy as np
from qiskit import QuantumCircuit
from qiskit.quantum_info import SparsePauliOp
from .config import InitialState, Model


def hamiltonian(model: Model) -> SparsePauliOp:
    return SparsePauliOp.from_list([
        ("IY", np.pi / model.period_scn_h),
        ("YI", np.pi / model.period_liver_h),
        ("XX", model.j_x_per_h),
        ("ZZ", model.j_z_per_h),
    ])


def preparation(initial: InitialState) -> QuantumCircuit:
    circuit = QuantumCircuit(2)
    for qubit, theta, phi in ((0, initial.scn_theta, initial.scn_phi),
                              (1, initial.liver_theta, initial.liver_phi)):
        circuit.ry(theta, qubit)
        circuit.rz(phi, qubit)
    return circuit


def append_step(circuit: QuantumCircuit, model: Model, dt_h: float) -> None:
    """Second-order Strang splitting, local/2 -> coupling -> local/2.

    R_P(theta)=exp(-i theta P/2). XX and ZZ commute with each other.
    """
    for qubit, period in ((0, model.period_scn_h), (1, model.period_liver_h)):
        circuit.ry(np.pi * dt_h / period, qubit)
    circuit.rxx(2 * model.j_x_per_h * dt_h, 0, 1)
    circuit.rzz(2 * model.j_z_per_h * dt_h, 0, 1)
    for qubit, period in ((0, model.period_scn_h), (1, model.period_liver_h)):
        circuit.ry(np.pi * dt_h / period, qubit)
