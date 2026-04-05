import os
from pathlib import Path

BASE_DIR = Path(r"C:\FIBRA CADASTRO")
PYTHON_EXE = Path(r"C:\Python314\python.exe")
ETL_SCRIPT = BASE_DIR / "etl_telegram_rede_optica.py"
CHATEXPORT_DIR = BASE_DIR

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
MODEL = "gpt-5.4"