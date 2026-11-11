"""Make Hatchling's editable path readable under Windows legacy locales.

Run with python -S so an existing non-ASCII .pth cannot prevent startup.
"""
from pathlib import Path


def main():
    root = Path(__file__).resolve().parent
    pth = root / '.venv/Lib/site-packages/_editable_impl_qc_clock_model.pth'
    if not pth.is_file():
        raise SystemExit(f'Editable installation path file missing: {pth}')
    source = str(root / 'src')
    # ascii() escapes every non-ASCII character; Python decodes the literal at
    # startup rather than asking the locale codec to decode the path itself.
    pth.write_text(f'import sys; sys.path.insert(0, {ascii(source)})\n', encoding='ascii')
    print('Editable source path repaired (ASCII-safe .pth).')


if __name__ == '__main__':
    main()
