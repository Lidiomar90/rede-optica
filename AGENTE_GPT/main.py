"""
Agente IA — ETL Rede Óptica MG
Usa Chat Completions API (compatível com OpenAI, OpenRouter e DeepSeek).
"""
import json
import sys
from openai import OpenAI
from config import API_KEY, API_BASE, MODEL, BACKEND, EXTRA_HEADERS
from tools_etl import (
    find_latest_result_json,
    run_pilot,
    run_dry_run,
    run_commit,
    promote_batch,
    rollback_batch,
    read_latest_report,
)

# ── Validação de configuração ──────────────────────────────────────────────
if not API_KEY:
    print("[ERRO] Nenhuma chave de API configurada.")
    print("       Edite: privado\\chaves_ia.env")
    print("       Adicione uma das chaves:")
    print("         OPENROUTER_KEY=sk-or-v1-...")
    print("         DEEPSEEK_KEY=sk-...")
    print("         OPENAI_KEY=sk-...")
    sys.exit(1)

print(f"[INFO] Backend: {BACKEND.upper()}  |  Modelo: {MODEL}")

# ── Cliente OpenAI-compatível ──────────────────────────────────────────────
client = OpenAI(
    api_key=API_KEY,
    base_url=API_BASE,
    default_headers=EXTRA_HEADERS,
)

# ── Definição das ferramentas (função → schema) ────────────────────────────
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "find_latest_result_json",
            "description": "Localiza o result.json mais recente do Telegram.",
            "parameters": {"type": "object", "properties": {}, "required": []},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "run_pilot",
            "description": "Executa o piloto do ETL (modo teste, sem gravar no banco).",
            "parameters": {"type": "object", "properties": {}, "required": []},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "run_dry_run",
            "description": "Executa dry-run do ETL usando o JSON informado.",
            "parameters": {
                "type": "object",
                "properties": {"json_path": {"type": "string", "description": "Caminho do result.json"}},
                "required": ["json_path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "run_commit",
            "description": "Executa commit do ETL. APENAS após aprovação explícita do usuário.",
            "parameters": {
                "type": "object",
                "properties": {"json_path": {"type": "string"}},
                "required": ["json_path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "promote_batch",
            "description": "Promove batch para produção. APENAS após aprovação explícita do usuário.",
            "parameters": {
                "type": "object",
                "properties": {"batch_id": {"type": "string"}},
                "required": ["batch_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "rollback_batch",
            "description": "Faz rollback de batch. APENAS após aprovação explícita do usuário.",
            "parameters": {
                "type": "object",
                "properties": {"batch_id": {"type": "string"}},
                "required": ["batch_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "read_latest_report",
            "description": "Lê o último relatório TXT/CSV gerado pelo ETL.",
            "parameters": {"type": "object", "properties": {}, "required": []},
        },
    },
]


def dispatch(name: str, args: dict):
    """Executa a ferramenta solicitada pelo agente."""
    mapping = {
        "find_latest_result_json": lambda: find_latest_result_json(),
        "run_pilot":               lambda: run_pilot(),
        "run_dry_run":             lambda: run_dry_run(args["json_path"]),
        "run_commit":              lambda: run_commit(args["json_path"]),
        "promote_batch":           lambda: promote_batch(args["batch_id"]),
        "rollback_batch":          lambda: rollback_batch(args["batch_id"]),
        "read_latest_report":      lambda: read_latest_report(),
    }
    if name not in mapping:
        raise ValueError(f"Ferramenta desconhecida: {name}")
    return mapping[name]()


def main():
    mensagens = [
        {
            "role": "system",
            "content": (
                "Você é um agente ETL da Rede Óptica MG. "
                "Seu objetivo é operar o ETL do Telegram de forma segura e eficiente. "
                "Fluxo padrão: 1) localizar JSON, 2) rodar piloto, 3) rodar dry-run, 4) ler relatório. "
                "NUNCA execute commit, promote ou rollback sem pedir aprovação explícita ao usuário. "
                "Responda sempre em português brasileiro."
            ),
        },
        {
            "role": "user",
            "content": (
                "Inicie o fluxo ETL: localize o JSON do Telegram, rode o piloto, "
                "execute o dry-run e me mostre o relatório. "
                "Aguarde minha aprovação antes de qualquer operação de escrita."
            ),
        },
    ]

    max_iteracoes = 10
    for iteracao in range(max_iteracoes):
        print(f"\n[Iteração {iteracao + 1}]", flush=True)

        resposta = client.chat.completions.create(
            model=MODEL,
            messages=mensagens,
            tools=TOOLS,
            tool_choice="auto",
        )

        msg = resposta.choices[0].message
        mensagens.append(msg.model_dump(exclude_unset=True))

        # Sem tool_calls → agente concluiu
        if not msg.tool_calls:
            print("\n── Resposta final do agente ──")
            print(msg.content or "(sem texto)")
            break

        # Processa cada tool_call
        for tc in msg.tool_calls:
            nome = tc.function.name
            args = json.loads(tc.function.arguments or "{}")
            print(f"  → Ferramenta: {nome}({args})", flush=True)

            try:
                resultado = dispatch(nome, args)
            except Exception as e:
                resultado = {"erro": str(e)}

            mensagens.append({
                "role":         "tool",
                "tool_call_id": tc.id,
                "content":      json.dumps(resultado, ensure_ascii=False)[:8000],
            })
    else:
        print("\n[AVISO] Limite de iterações atingido.")


if __name__ == "__main__":
    main()
