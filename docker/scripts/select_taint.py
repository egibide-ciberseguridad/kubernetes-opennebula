#!/usr/bin/env python3
"""
Script interactivo para listar recursos de Terraform y marcarlos como tainted.
Se usa con `make taint` (sin parámetros) para seleccionar recursos.
"""

import subprocess
import sys
import os
import re
import tty
import termios


def discover_terraform_resources(terraform_dir: str) -> list[str]:
    """Escanea los archivos .tf y extrae todos los recursos."""
    resources = []
    pattern = re.compile(r'^resource\s+"([^"]+)"\s+"([^"]+)"', re.MULTILINE)

    for root, _dirs, files in os.walk(terraform_dir):
        for fname in sorted(files):
            if fname.endswith('.tf'):
                filepath = os.path.join(root, fname)
                try:
                    with open(filepath, 'r') as f:
                        content = f.read()
                    for match in pattern.finditer(content):
                        res_type = match.group(1)
                        res_name = match.group(2)
                        resources.append(f"{res_type}.{res_name}")
                except Exception:
                    pass

    return sorted(set(resources))


def interactive_select(resources):
    """Interfaz interactiva para seleccionar recursos."""
    selected = set()
    cursor = 0

    fd = sys.stdin.fileno()
    old_attrs = termios.tcgetattr(fd)  # Una sola llamada

    try:
        # Configurar terminal para modo raw (una vez)
        attrs = old_attrs  # Reutilizamos old_attrs
        attrs[3] = attrs[3] & ~termios.ECHO & ~termios.ICANON
        attrs[6][termios.VMIN] = 0
        attrs[6][termios.VTIME] = 1
        termios.tcsetattr(fd, termios.TCSADRAIN, attrs)

        while True:
            os.system('clear' if os.name != 'nt' else 'cls')
            print("=" * 65)
            print("  Selecciona recursos para marcar como TAINED")
            print("=" * 65)
            print()

            start = max(0, cursor - 6)
            end = min(len(resources), start + 15)

            for i in range(start, end):
                res = resources[i]
                marker = "✔" if res in selected else " "
                highlight = ">>>" if i == cursor else "   "
                print(f"  {highlight}[{marker}] {res}")

            print()
            print("  [↑/↓] Navegar  [ESPACIO] Seleccionar  [q] Aceptar  [ESC] Cancelar")
            print(f"  Seleccionados: {len(selected)}/{len(resources)}")
            print("=" * 65)

            # Leer una tecla
            key = sys.stdin.read(1)

            if key == '\x1b':  # Escape - leer siguiente byte
                key2 = sys.stdin.read(1)
                if key2 == '[':
                    key3 = sys.stdin.read(1)
                    if key3 == 'A':  # Up arrow
                        cursor = max(0, cursor - 1)
                        continue
                    elif key3 == 'B':  # Down arrow
                        cursor = min(len(resources) - 1, cursor + 1)
                        continue
                # Si no es una flecha, es Escape puro
                print("\n  Cancelado.")
                sys.exit(0)
            elif key == 'q':
                break
            elif key == '\n' or key == ' ':  # Enter or Space
                if 0 <= cursor < len(resources):
                    res = resources[cursor]
                    if res in selected:
                        selected.discard(res)
                    else:
                        selected.add(res)

    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_attrs)

    return list(selected)


def main():
    terraform_dir = os.environ.get('TF_DIR', 'terraform')
    if not os.path.isabs(terraform_dir):
        terraform_dir = os.path.join(os.getcwd(), terraform_dir)

    if not os.path.isdir(terraform_dir):
        print(f"Error: Directorio de Terraform no encontrado: {terraform_dir}")
        sys.exit(1)

    resources = discover_terraform_resources(terraform_dir)

    if not resources:
        print("No se encontraron recursos de Terraform.")
        sys.exit(1)

    print(f"Se encontraron {len(resources)} recursos de Terraform.\n")

    selected = interactive_select(resources)

    if not selected:
        print("\nNingún recurso seleccionado. Cancelado.")
        sys.exit(0)

    print(f"\nMarcando {len(selected)} recurso(s) como tainted...")

    for resource in selected:
        print(f"  → {resource}...", end=' ')
        result = subprocess.run(
            ['terraform', '-chdir=/terraform', 'taint', resource],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print("OK")
        else:
            print(f"ERROR: {result.stderr.strip()}")

    print("\n¡Listo!")


if __name__ == '__main__':
    main()
