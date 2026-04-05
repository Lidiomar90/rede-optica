import json
import subprocess
from pathlib import Path
from config import BASE_DIR, PYTHON_EXE, ETL_SCRIPT, CHATEXPORT_DIR

def find_latest_result_json() -> str:
    files = sorted(
        CHATEXPORT_DIR.rglob("result.json"),
        key=lambda p: p.stat().st_mtime,
        reverse=True
    )
    if not files:
        raise FileNotFoundError("Nenhum result.json encontrado.")
    return str(files[0])

def run_command(args: list[str]) -> dict:
    proc = subprocess.run(
        args,
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )
    return {
        "ok": proc.returncode == 0,
        "returncode": proc.returncode,
        "stdout": proc.stdout[-12000:],
        "stderr": proc.stderr[-12000:],
    }

def run_pilot() -> dict:
    return run_command([str(PYTHON_EXE), str(ETL_SCRIPT), "--piloto"])

def run_dry_run(json_path: str) -> dict:
    return run_command([str(PYTHON_EXE), str(ETL_SCRIPT), "--input", json_path, "--dry-run"])

def run_commit(json_path: str) -> dict:
    return run_command([str(PYTHON_EXE), str(ETL_SCRIPT), "--input", json_path, "--commit"])

def promote_batch(batch_id: str) -> dict:
    return run_command([str(PYTHON_EXE), str(ETL_SCRIPT), "--promote", batch_id])

def rollback_batch(batch_id: str) -> dict:
    return run_command([str(PYTHON_EXE), str(ETL_SCRIPT), "--rollback", batch_id])

def read_latest_report() -> dict:
    log_dir = BASE_DIR / "logs"
    txts = sorted(log_dir.glob("relatorio_etl_*.txt"), key=lambda p: p.stat().st_mtime, reverse=True)
    csvs = sorted(log_dir.glob("relatorio_etl_*_pendencias.csv"), key=lambda p: p.stat().st_mtime, reverse=True)

    out = {}
    if txts:
        out["txt_path"] = str(txts[0])
        out["txt_content"] = txts[0].read_text(encoding="utf-8", errors="ignore")[-12000:]
    if csvs:
        out["csv_path"] = str(csvs[0])
    return out	