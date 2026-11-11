"""Dependency-free SVG plots of saved simulation observables."""
import argparse
import csv
from pathlib import Path
from html import escape

COLORS = ['#2563eb', '#ea7b22']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    args = parser.parse_args()
    with (args.input / 'observables.csv').open(encoding='utf-8') as f:
        rows = [{k: float(v) for k, v in r.items()} for r in csv.DictReader(f)]
    out = args.input / 'figures'
    out.mkdir(exist_ok=True)
    times = [r['time_h'] for r in rows]
    panels = []
    for axis in 'xyz':
        panels.append((f'Expectation value: {axis.upper()}',
                       [[r[f'{q}_{axis}'] for r in rows] for q in ['scn', 'liver']],
                       ['SCN', 'Liver'], -1.05, 1.05))
    panels.append(('Reduced-state purity',
                   [[(1+sum(r[f'{q}_{a}']**2 for a in 'xyz'))/2 for r in rows]
                    for q in ['scn', 'liver']], ['SCN', 'Liver'], .48, 1.02))
    def draw(filename, title, panels):
        svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800" viewBox="0 0 1200 800">',
               '<rect width="1200" height="800" fill="#f8fafc"/>',
               '<style>text{font-family:Arial,sans-serif;fill:#334155;font-size:13px}</style>',
               f'<text x="40" y="35" style="font-size:23px;font-weight:bold">{escape(title)}</text>',
               '<text x="40" y="60">Illustrative two-qubit model | 48 hours | not fitted physiological data</text>']
        for n, (label, series, names, lo, hi) in enumerate(panels):
            x, y = 80 + (n%2)*580, 125+(n//2)*340
            w, h = 480, 230
            svg.append(f'<text x="{x}" y="{y-24}" style="font-size:17px;font-weight:bold">{escape(label)}</text>')
            for j in range(5):
                yy = y+h-j*h/4
                svg.append(f'<path d="M{x},{yy} h{w}" stroke="#dbe3ed"/><text x="{x-10}" y="{yy+4}" text-anchor="end">{lo+(hi-lo)*j/4:.2g}</text>')
            for tick in range(0, 49, 12):
                xx = x+w*(tick-times[0])/(times[-1]-times[0])
                svg.append(f'<text x="{xx}" y="{y+h+22}" text-anchor="middle">{tick}</text>')
            svg.append(f'<text x="{x+w/2}" y="{y+h+45}" text-anchor="middle">Time (h)</text>')
            for k, values in enumerate(series):
                points = ' '.join(f'{x+w*(t-times[0])/(times[-1]-times[0]):.2f},{y+h*(hi-v)/(hi-lo):.2f}' for t,v in zip(times,values))
                color = COLORS[k%2]
                svg.append(f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="2.2"/>')
                svg.append(f'<text x="{x+300+k*85}" y="{y-7}" style="fill:{color}">{escape(names[k])}</text>')
        svg.append('</svg>')
        (out / filename).write_text('\n'.join(svg), encoding='utf-8')
    draw('observables.svg', 'Two-qubit oscillations and local purity', panels)
    print('Saved figures/observables.svg')


if __name__ == '__main__':
    main()
