import os
import sys
import subprocess
import pytest


def test_alembic_heads():
    backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    alembic_exe = os.path.join(backend_dir, ".venv", "Scripts", "alembic.exe")
    if not os.path.exists(alembic_exe):
        pytest.skip("alembic.exe not found in .venv")

    res = subprocess.run(
        [alembic_exe, "heads"],
        cwd=backend_dir,
        capture_output=True,
        text=True,
    )
    assert res.returncode == 0
    assert "0cf1f03dce0a" in res.stdout


def test_alembic_check():
    backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    alembic_exe = os.path.join(backend_dir, ".venv", "Scripts", "alembic.exe")
    if not os.path.exists(alembic_exe):
        pytest.skip("alembic.exe not found in .venv")

    res = subprocess.run(
        [alembic_exe, "check"],
        cwd=backend_dir,
        capture_output=True,
        text=True,
    )
    assert res.returncode == 0
