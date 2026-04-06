import os
import sys
import json
import time
import socket
import shutil
import platform
import subprocess
from pathlib import Path
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

ROOT = Path(r"C:\FIBRA CADASTRO")
CONFIG_PATH = ROOT / "agente_config.json"
REPORTS_DIR = ROOT / "logs_agente"
PUBLIC_FILES = [
    "index.html",
    "mapa-rede-optica.html",
    "dashboard.html",
    "ia-assistente.html",
    "auditoria-revisao.html",
]
SENSITIVE_FILES = [
    ".github_token",
    ".openai_api_key",
    ".claude_api_key",
    ".supabase_key",
    ".env",
]
URLS = {
    "portal": "https://lidiomar90.github.io/rede-optica/",
    "mapa": "https://lidiomar90.github.io/rede-optica/mapa-rede-optica.html",
    "dashboard": "https://lidiomar90.github.io/rede-optica/dashboard.html",
    "ia": "https://lidiomar90.github.io/rede-optica/ia-assistente.html",
    "auditoria": "https://lidiomar90.github.io/rede-optica/auditoria-revisao.html",
}


def now_str() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def ensure_dirs() -> None:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)


def run_cmd(cmd, cwd=None, timeout=120):
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
            shell=False,
        )
        return {
            "ok": result.returncode == 0,
            "code": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
        }
    except Exception as exc:
        return {"ok": False, "code": -1, "stdout": "", "stderr": str(exc)}


class GuardiaoRedeOptica:
    def __init__(self):
        ensure_dirs()
        self.root = ROOT
        self.config = self._load_config()
        self.report = {
            "executado_em": now_str(),
            "ambiente": {},
            "checks": [],
            "correcoes": [],
            "resumo": {},
        }

    def _load_config(self):
        default = {
            "auto_fix_safe": True,
            "abrir_site_apos_publicar": False,
            "timeout_http": 15,
            "backup_before_fix": True,
            "modo_online": True,
            "modo_pc": True,
        }
        if CONFIG_PATH.exists():
            try:
                data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
                default.update(data)
            except Exception:
                pass
        else:
            CONFIG_PATH.write_text(json.dumps(default, indent=2, ensure_ascii=False), encoding="utf-8")
        return default

    def add_check(self, nome, ok, detalhe, categoria="geral"):
        self.report["checks"].append({
            "nome": nome,
            "ok": ok,
            "categoria": categoria,
            "detalhe": detalhe,
            "timestamp": now_str(),
        })

    def add_fix(self, nome, ok, detalhe):
        self.report["correcoes"].append({
            "nome": nome,
            "ok": ok,
            "detalhe": detalhe,
            "timestamp": now_str(),
        })

    def collect_environment(self):
        self.report["ambiente"] = {
            "hostname": socket.gethostname(),
            "platform": platform.platform(),
            "python": sys.version,
            "root": str(self.root),
            "cwd": os.getcwd(),
        }

    def check_root(self):
        ok = self.root.exists()
        self.add_check("Pasta principal", ok, str(self.root), "pc")
        return ok

    def check_public_files(self):
        missing = [f for f in PUBLIC_FILES if not (self.root / f).exists()]
        ok = len(missing) == 0
        detalhe = "Todos os arquivos encontrados" if ok else f"Ausentes: {missing}"
        self.add_check("Arquivos públicos", ok, detalhe, "pc")
        return ok

    def check_sensitive_files(self):
        found = [f for f in SENSITIVE_FILES if (self.root / f).exists()]
        ok = len(found) == 0
        detalhe = "Nenhum arquivo sensível encontrado" if ok else f"Sensíveis presentes: {found}"
        self.add_check("Arquivos sensíveis no projeto", ok, detalhe, "seguranca")
        if not ok and self.config.get("auto_fix_safe", True):
            privado = self.root / "privado"
            privado.mkdir(exist_ok=True)
            moved = []
            for name in found:
                src = self.root / name
                dst = privado / name
                try:
                    if dst.exists():
                        dst.unlink()
                    shutil.move(str(src), str(dst))
                    moved.append(name)
                except Exception as exc:
                    self.add_fix("Mover arquivo sensível", False, f"Falha ao mover {name}: {exc}")
            if moved:
                self.add_fix("Mover arquivos sensíveis", True, f"Movidos para {privado}: {moved}")
        return ok

    def check_git_repo(self):
        git_dir = self.root / ".git"
        ok = git_dir.exists()
        self.add_check("Repositório Git", ok, ".git encontrado" if ok else ".git ausente", "git")
        return ok

    def check_git_status(self):
        result = run_cmd(["git", "status", "--short"], cwd=self.root)
        ok = result["ok"]
        detail = result["stdout"] if result["stdout"] else "Sem alterações pendentes"
        if not result["ok"]:
            detail = result["stderr"]
        self.add_check("Git status", ok, detail, "git")
        return result

    def check_git_remote(self):
        result = run_cmd(["git", "remote", "-v"], cwd=self.root)
        ok = result["ok"] and "github.com" in (result["stdout"] or "")
        detail = result["stdout"] if result["stdout"] else result["stderr"]
        self.add_check("Git remote", ok, detail, "git")
        return result

    def ensure_gitignore(self):
        desired = [
            ".env",
            ".env.*",
            ".github_token",
            ".openai_api_key",
            ".claude_api_key",
            ".supabase_key",
            "*.key",
            "telegram/",
            "logs/",
            "privado/",
            "*.dwg",
            "*.apk",
            "*.zip",
            "*.rar",
            "*.7z",
        ]
        path = self.root / ".gitignore"
        existing = path.read_text(encoding="utf-8", errors="ignore").splitlines() if path.exists() else []
        changed = False
        for item in desired:
            if item not in existing:
                existing.append(item)
                changed = True
        if changed:
            if self.config.get("backup_before_fix", True) and path.exists():
                shutil.copy2(path, self.root / f".gitignore.bkp_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
            path.write_text("\n".join(existing) + "\n", encoding="utf-8")
            self.add_fix("Atualizar .gitignore", True, "Entradas de segurança adicionadas")
        else:
            self.add_check(".gitignore", True, "Já contém proteções principais", "git")

    def check_connectivity(self):
        try:
            socket.create_connection(("github.com", 443), timeout=8).close()
            self.add_check("Conectividade GitHub", True, "github.com:443 acessível", "online")
            return True
        except Exception as exc:
            self.add_check("Conectividade GitHub", False, str(exc), "online")
            return False

    def http_check(self, name, url):
        try:
            req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urlopen(req, timeout=self.config.get("timeout_http", 15)) as resp:
                code = getattr(resp, "status", 200)
                ok = 200 <= code < 400
                self.add_check(f"Site online: {name}", ok, f"HTTP {code} - {url}", "online")
                return ok
        except HTTPError as exc:
            self.add_check(f"Site online: {name}", False, f"HTTP {exc.code} - {url}", "online")
            return False
        except URLError as exc:
            self.add_check(f"Site online: {name}", False, f"URL Error - {exc}", "online")
            return False
        except Exception as exc:
            self.add_check(f"Site online: {name}", False, str(exc), "online")
            return False

    def check_all_urls(self):
        for name, url in URLS.items():
            self.http_check(name, url)

    def check_publish_script(self):
        path = self.root / "PUBLICAR-GIT.ps1"
        if not path.exists():
            self.add_check("Script de publicação", False, "PUBLICAR-GIT.ps1 não encontrado", "pc")
            return
        text = path.read_text(encoding="utf-8", errors="ignore")
        bad_pattern = "2>&1"
        if bad_pattern in text:
            self.add_check("Script de publicação", False, "Usa redirecionamento 2>&1 que pode gerar falso erro", "pc")
            if self.config.get("auto_fix_safe", True):
                fixed = text.replace(
                    "git push $URL_TOKEN main --force 2>&1",
                    "$pushOutput = git push $URL_TOKEN main --force 2>&1\nif ($LASTEXITCODE -ne 0) { throw ($pushOutput | Out-String) }\n$pushOutput | Out-Host"
                )
                if fixed != text:
                    if self.config.get("backup_before_fix", True):
                        shutil.copy2(path, self.root / f"PUBLICAR-GIT.ps1.bkp_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
                    path.write_text(fixed, encoding="utf-8")
                    self.add_fix("Corrigir PUBLICAR-GIT.ps1", True, "Tratamento de push ajustado")
        else:
            self.add_check("Script de publicação", True, "Sem padrão de falso erro identificado", "pc")

    def optional_git_add_commit(self):
        status = run_cmd(["git", "status", "--porcelain"], cwd=self.root)
        if not status["ok"]:
            self.add_fix("Preparar commit", False, status["stderr"])
            return
        if not status["stdout"].strip():
            self.add_check("Pendências para commit", True, "Nada novo para versionar", "git")
            return

        allowlist = [
            ".gitignore",
            ".env.example",
            "index.html",
            "mapa-rede-optica.html",
            "dashboard.html",
            "ia-assistente.html",
            "auditoria-revisao.html",
            "PUBLICAR-GIT.ps1",
        ]
        for item in allowlist:
            if (self.root / item).exists():
                run_cmd(["git", "add", item], cwd=self.root)

        status2 = run_cmd(["git", "status", "--porcelain"], cwd=self.root)
        if status2["stdout"].strip():
            msg = f"auto-fix guardiao {datetime.now().strftime('%d/%m/%Y %H:%M')}"
            commit = run_cmd(["git", "commit", "-m", msg], cwd=self.root)
            self.add_fix("Commit automático seguro", commit["ok"], commit["stdout"] or commit["stderr"])

    def save_report(self):
        total = len(self.report["checks"])
        ok = sum(1 for x in self.report["checks"] if x["ok"])
        fail = total - ok
        self.report["resumo"] = {
            "total_checks": total,
            "ok": ok,
            "falhas": fail,
            "correcoes": len(self.report["correcoes"]),
        }
        path = REPORTS_DIR / f"relatorio_guardiao_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        path.write_text(json.dumps(self.report, indent=2, ensure_ascii=False), encoding="utf-8")
        return path

    def print_summary(self, report_path: Path):
        print("\n" + "=" * 70)
        print("GUARDIÃO REDE ÓPTICA MG — RESUMO")
        print("=" * 70)
        print(f"Executado em: {self.report['executado_em']}")
        print(f"Pasta: {self.root}")
        print(f"Checks OK: {self.report['resumo']['ok']}")
        print(f"Checks com falha: {self.report['resumo']['falhas']}")
        print(f"Correções aplicadas: {self.report['resumo']['correcoes']}")
        print(f"Relatório: {report_path}")
        print("-" * 70)
        for item in self.report["checks"]:
            status = "OK" if item["ok"] else "FALHA"
            print(f"[{status}] {item['categoria']} | {item['nome']} -> {item['detalhe']}")
        if self.report["correcoes"]:
            print("-" * 70)
            for item in self.report["correcoes"]:
                status = "OK" if item["ok"] else "FALHA"
                print(f"[FIX {status}] {item['nome']} -> {item['detalhe']}")
        print("=" * 70 + "\n")

    def run(self):
        self.collect_environment()
        if not self.check_root():
            path = self.save_report()
            self.print_summary(path)
            return
        self.check_public_files()
        self.check_sensitive_files()
        self.check_git_repo()
        self.check_git_status()
        self.check_git_remote()
        self.ensure_gitignore()
        self.check_publish_script()
        if self.config.get("modo_online", True) and self.check_connectivity():
            self.check_all_urls()
        if self.config.get("auto_fix_safe", True):
            self.optional_git_add_commit()
        path = self.save_report()
        self.print_summary(path)


if __name__ == "__main__":
    GuardiaoRedeOptica().run()
