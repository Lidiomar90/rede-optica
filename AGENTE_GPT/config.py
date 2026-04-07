"""
Configuração do Agente IA — Rede Óptica MG
Suporta OpenAI, OpenRouter (DeepSeek/Llama grátis) e DeepSeek direto.
Carregamento de chaves: lê de variáveis de ambiente ou de privado/chaves_ia.env
"""
import os
from pathlib import Path

# ── Caminhos ───────────────────────────────────────────────────────────────
BASE_DIR       = Path(r"C:\FIBRA CADASTRO")
PYTHON_EXE     = Path(r"C:\Python314\python.exe")
ETL_SCRIPT     = BASE_DIR / "etl_telegram_rede_optica.py"
CHATEXPORT_DIR = BASE_DIR
CHAVES_ENV     = BASE_DIR / "privado" / "chaves_ia.env"


def _carregar_env_file(path: Path) -> None:
    """Lê chave=valor de um arquivo .env e exporta para os.environ."""
    if not path.exists():
        return
    for linha in path.read_text(encoding="utf-8").splitlines():
        linha = linha.strip()
        if not linha or linha.startswith("#") or "=" not in linha:
            continue
        chave, _, valor = linha.partition("=")
        chave = chave.strip()
        valor = valor.strip()
        if chave and valor and chave not in os.environ:
            os.environ[chave] = valor


# Carrega o env file antes de ler as variáveis
_carregar_env_file(CHAVES_ENV)

# ── Chaves ─────────────────────────────────────────────────────────────────
OPENAI_KEY      = os.getenv("OPENAI_KEY", "").strip()
OPENROUTER_KEY  = os.getenv("OPENROUTER_KEY", "").strip()
DEEPSEEK_KEY    = os.getenv("DEEPSEEK_KEY", "").strip()
GEMINI_KEY      = os.getenv("GEMINI_KEY", "").strip()

# ── Seleção automática de backend ──────────────────────────────────────────
# Prioridade: DeepSeek direto > OpenAI > OpenRouter
if DEEPSEEK_KEY:
    API_KEY  = DEEPSEEK_KEY
    API_BASE = "https://api.deepseek.com/v1"
    MODEL    = "deepseek-chat"
    BACKEND  = "deepseek"
elif OPENAI_KEY:
    API_KEY  = OPENAI_KEY
    API_BASE = "https://api.openai.com/v1"
    MODEL    = "gpt-4o-mini"
    BACKEND  = "openai"
elif OPENROUTER_KEY:
    API_KEY  = OPENROUTER_KEY
    API_BASE = "https://openrouter.ai/api/v1"
    # DeepSeek R1 gratuito via OpenRouter
    MODEL    = "deepseek/deepseek-r1:free"
    BACKEND  = "openrouter"
else:
    API_KEY  = ""
    API_BASE = ""
    MODEL    = ""
    BACKEND  = "none"

EXTRA_HEADERS: dict = {}
if BACKEND == "openrouter":
    EXTRA_HEADERS = {
        "HTTP-Referer": "https://github.com/Lidiomar90/rede-optica",
        "X-Title":      "Rede Optica MG Agente",
    }
