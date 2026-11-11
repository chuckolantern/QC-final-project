"""Physics checks, independent exact reference, ordering and convergence."""

from dataclasses import replace
import numpy as np
import pytest
from scipy.linalg import expm
from qc_clock import Config, InitialState, Model, Simulation, load_config, simulate
from qc_clock.simulator import time_grid


def exact_rho(config, time):
    # Independently construct matrices in Qiskit's little-endian ordering.
    identity = np.eye(2)
    x = np.array([[0, 1], [1, 0]])
    y = np.array([[0, -1j], [1j, 0]])
    z = np.diag([1, -1])
    m = config.model
    h = (np.pi / m.period_scn_h * np.kron(identity, y)
         + np.pi / m.period_liver_h * np.kron(y, identity)
         + m.j_x_per_h * np.kron(x, x) + m.j_z_per_h * np.kron(z, z))
    initial = config.initial
    def state(theta, phi):
        return np.array([np.cos(theta / 2) * np.exp(-1j * phi / 2),
                         np.sin(theta / 2) * np.exp(1j * phi / 2)])
    psi = np.kron(state(initial.liver_theta, initial.liver_phi), state(initial.scn_theta, initial.scn_phi))
    psi = expm(-1j * h * time) @ psi
    return np.outer(psi, psi.conj())


def test_uncoupled_analytic_and_qubit_order():
    config = Config(model=Model(j_x_per_h=0, j_z_per_h=0),
                    simulation=Simulation(duration_h=26, output_step_h=0.2, max_step_h=0.1))
    result = simulate(config)
    for i, period in enumerate((24.5, 25.2)):
        angle = 2 * np.pi * result.times_h / period
        np.testing.assert_allclose(result.bloch[:, i, 2], np.cos(angle), atol=1e-11)
        np.testing.assert_allclose(result.bloch[:, i, 0], np.sin(angle), atol=1e-11)


def test_coupled_reference_and_second_order():
    config = Config(model=Model(j_x_per_h=0.07, j_z_per_h=-0.03),
                    initial=InitialState(0.4, 0.2, 1.1, -0.7),
                    simulation=Simulation(duration_h=8, output_step_h=1, max_step_h=0.2))
    exact = exact_rho(config, 8)
    coarse = simulate(config)
    fine = simulate(replace(config, simulation=replace(config.simulation, max_step_h=0.1)))
    error_coarse = np.linalg.norm(coarse.density_matrices[-1] - exact)
    error_fine = np.linalg.norm(fine.density_matrices[-1] - exact)
    assert 3.8 < error_coarse / error_fine < 4.2
    assert error_fine < 1e-4
    np.testing.assert_allclose(fine.purity, 1, atol=1e-11)
    assert fine.min_eigenvalue.min() > -1e-11
    assert fine.trace_error.max() < 1e-11


def test_independent_initial_state():
    config = Config(model=Model(j_x_per_h=0, j_z_per_h=0),
                    simulation=Simulation(duration_h=3, output_step_h=0.3))
    a = simulate(config)
    b = simulate(replace(config, initial=InitialState(liver_theta=1.3, liver_phi=0.5)))
    np.testing.assert_allclose(a.bloch[:, 0], b.bloch[:, 0], atol=1e-12)


def test_partial_output_interval():
    np.testing.assert_allclose(time_grid(0.25, 0.1), [0, 0.1, 0.2, 0.25])
    assert len(time_grid(0.3, 0.1)) == 4


@pytest.mark.parametrize("kwargs", [{"period_scn_h": 0}, {"j_x_per_h": float("nan")}])
def test_invalid_model(kwargs):
    with pytest.raises(ValueError):
        Config(model=Model(**kwargs))


def test_unknown_config_key(tmp_path):
    path = tmp_path / "bad.toml"
    path.write_text("[model]\nperiod_typo = 24\n", encoding="utf-8")
    with pytest.raises(TypeError):
        load_config(path)
