"""Validated configuration; unknown TOML keys are rejected by dataclasses."""

from dataclasses import asdict, dataclass, field
from pathlib import Path
import math
import tomllib


@dataclass(frozen=True)
class Model:
    period_scn_h: float = 24.5
    period_liver_h: float = 25.2
    j_x_per_h: float = 0.01
    j_z_per_h: float = 0.01


@dataclass(frozen=True)
class InitialState:
    scn_theta: float = 0.0
    scn_phi: float = 0.0
    liver_theta: float = 0.0
    liver_phi: float = 0.0


@dataclass(frozen=True)
class Simulation:
    duration_h: float = 48.0
    output_step_h: float = 0.1
    max_step_h: float = 0.05
    seed: int = 2026


@dataclass(frozen=True)
class Config:
    model: Model = field(default_factory=Model)
    initial: InitialState = field(default_factory=InitialState)
    simulation: Simulation = field(default_factory=Simulation)

    def __post_init__(self):
        for group in (self.model, self.initial, self.simulation):
            for name, value in asdict(group).items():
                if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
                    raise ValueError(f"{name} must be a finite number")
        for name in ("period_scn_h", "period_liver_h"):
            if getattr(self.model, name) <= 0:
                raise ValueError(f"{name} must be positive")
        for name in ("duration_h", "output_step_h", "max_step_h"):
            if getattr(self.simulation, name) <= 0:
                raise ValueError(f"{name} must be positive")
        if not isinstance(self.simulation.seed, int) or self.simulation.seed < 0:
            raise ValueError("seed must be a nonnegative integer")


def load_config(path: str | Path) -> Config:
    with Path(path).open("rb") as stream:
        data = tomllib.load(stream)
    extra = data.keys() - {"model", "initial", "simulation"}
    if extra:
        raise ValueError(f"Unknown config sections: {sorted(extra)}")
    return Config(Model(**data.get("model", {})),
                  InitialState(**data.get("initial", {})),
                  Simulation(**data.get("simulation", {})))
