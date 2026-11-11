"""Plot an existing simulation without rerunning it."""
import argparse
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    args = parser.parse_args()
    with np.load(args.input / 'states.npz') as data:
        t, b, rho = data['times_h'], data['bloch'], data['density_matrices']
    out = args.input / 'figures'
    out.mkdir(exist_ok=True)
    plt.rcParams.update({'font.size': 10, 'axes.spines.top': False,
                         'axes.spines.right': False, 'figure.dpi': 130})
    colors = ['#2563eb', '#e07820']
    labels = ['SCN (qubit 0)', 'Liver (qubit 1)']
    fig, axes = plt.subplots(2, 2, figsize=(12, 7), constrained_layout=True)
    for k, ax in enumerate(axes.flat[:3]):
        for q in range(2):
            ax.plot(t, b[:, q, k], color=colors[q], label=labels[q])
        ax.set(xlabel='Time (h)', ylabel=f'<{"XYZ"[k]}>', ylim=(-1.05, 1.05))
        ax.grid(alpha=.2)
        ax.legend(loc='lower left', fontsize=8)
    local_purity = (1 + np.sum(b*b, axis=2)) / 2
    global_purity = np.einsum('tij,tji->t', rho, rho).real
    ax = axes[1, 1]
    for q in range(2):
        ax.plot(t, local_purity[:, q], color=colors[q], label=labels[q])
    ax.plot(t, global_purity, color='#374151', ls='--', label='Full two-qubit state')
    ax.set(xlabel='Time (h)', ylabel='Purity', ylim=(.48, 1.02))
    ax.grid(alpha=.2)
    ax.legend(fontsize=8)
    fig.suptitle('Two-qubit baseline | illustrative parameters, not fitted physiology')
    fig.savefig(out / 'observables.png')
    plt.close(fig)

    fig = plt.figure(figsize=(11, 5), constrained_layout=True)
    u, v = np.meshgrid(np.linspace(0, 2*np.pi, 36), np.linspace(0, np.pi, 20))
    for q in range(2):
        ax = fig.add_subplot(1, 2, q+1, projection='3d')
        ax.plot_wireframe(np.cos(u)*np.sin(v), np.sin(u)*np.sin(v), np.cos(v),
                          color='#94a3b8', alpha=.18, linewidth=.5)
        ax.plot(*b[:, q].T, color=colors[q], lw=1.7)
        ax.scatter(*b[0, q], color='green', s=45, label='Start')
        ax.scatter(*b[-1, q], color='red', marker='x', s=45, label='End')
        ax.set(xlabel='<X>', ylabel='<Y>', zlabel='<Z>', title=labels[q],
               xlim=(-1, 1), ylim=(-1, 1), zlim=(-1, 1))
        ax.set_box_aspect((1, 1, 1))
        ax.legend(fontsize=8)
    fig.suptitle('Reduced-state Bloch trajectories | inside sphere = mixed local state')
    fig.savefig(out / 'bloch_trajectories.png')
    plt.close(fig)

    trace = abs(np.trace(rho, axis1=1, axis2=2)-1)
    herm = np.max(abs(rho-rho.conj().transpose(0, 2, 1)), axis=(1, 2))
    minimum = np.linalg.eigvalsh(rho).min(axis=1)
    fig, axes = plt.subplots(1, 2, figsize=(11, 4), constrained_layout=True)
    for values, name in [(trace, 'Trace error'), (herm, 'Hermiticity error')]:
        axes[0].semilogy(t, np.maximum(values, 1e-18), label=name)
    axes[0].set(xlabel='Time (h)', ylabel='Absolute error (floor 1e-18)')
    axes[0].legend()
    axes[1].plot(t, minimum, color=colors[0])
    axes[1].axhline(0, color='gray', ls='--', lw=1)
    axes[1].set(xlabel='Time (h)', ylabel='Minimum density-matrix eigenvalue')
    for ax in axes:
        ax.grid(alpha=.2)
    fig.suptitle('Numerical state-validity checks (not a time-step convergence test)')
    fig.savefig(out / 'numerical_checks.png')
    plt.close(fig)
    print('Saved 3 plots in the input directory: figures/')


if __name__ == '__main__':
    main()
