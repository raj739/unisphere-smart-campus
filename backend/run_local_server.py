from pathlib import Path
import os
import sys


BACKEND_DIR = Path(__file__).resolve().parent
RUNTIME_PACKAGES = BACKEND_DIR / ".runtime_packages"

sys.path.insert(0, str(RUNTIME_PACKAGES))
sys.path.insert(0, str(BACKEND_DIR))
os.environ.setdefault(
    "DATABASE_URL",
    f"sqlite:///{(BACKEND_DIR / 'unisphere_flow.db').as_posix()}",
)

import uvicorn


if __name__ == "__main__":
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000)
