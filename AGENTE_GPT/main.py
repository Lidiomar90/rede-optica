from openai import OpenAI
import json
from config import OPENAI_API_KEY, MODEL
from tools_etl import (
    find_latest_result_json,
    run_pilot,
    run_dry_run,
    run_commit,
    promote_batch,
    rollback_batch,
    read_latest_report,
)

client = OpenAI(api_key=OPENAI_API_KEY)

TOOLS = [
    {
        "type": "function",
        "name": "find_latest_result_json",
        "description": "Localiza o result.json mais recente do Telegram.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "type": "function",
        "name": "run_pilot",
        "description": "Executa o piloto do ETL.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
    {
        "type": "function",
        "name": "run_dry_run",
        "description": "Executa dry-run do ETL usando o JSON informado.",
        "parameters": {
            "type": "object",
            "properties": {"json_path": {"type": "string"}},
            "required": ["json_path"],
        },
    },
    {
        "type": "function",
        "name": "run_commit",
        "description": "Executa commit do ETL usando o JSON informado. Só usar após aprovação humana.",
        "parameters": {
            "type": "object",
            "properties": {"json_path": {"type": "string"}},
            "required": ["json_path"],
        },
    },
    {
        "type": "function",
        "name": "promote_batch",
        "description": "Promove um batch para produção. Só usar após aprovação humana.",
        "parameters": {
            "type": "object",
            "properties": {"batch_id": {"type": "string"}},
            "required": ["batch_id"],
        },
    },
    {
        "type": "function",
        "name": "rollback_batch",
        "description": "Faz rollback de um batch. Só usar após aprovação humana.",
        "parameters": {
            "type": "object",
            "properties": {"batch_id": {"type": "string"}},
            "required": ["batch_id"],
        },
    },
    {
        "type": "function",
        "name": "read_latest_report",
        "description": "Lê o último relatório TXT/CSV gerado pelo ETL.",
        "parameters": {"type": "object", "properties": {}, "required": []},
    },
]

def dispatch(name: str, args: dict):
    if name == "find_latest_result_json":
        return find_latest_result_json()
    if name == "run_pilot":
        return run_pilot()
    if name == "run_dry_run":
        return run_dry_run(args["json_path"])
    if name == "run_commit":
        return run_commit(args["json_path"])
    if name == "promote_batch":
        return promote_batch(args["batch_id"])
    if name == "rollback_batch":
        return rollback_batch(args["batch_id"])
    if name == "read_latest_report":
        return read_latest_report()
    raise ValueError(f"Tool desconhecida: {name}")

def main():
    user_goal = (
        "Operar o ETL Telegram da Rede Óptica MG de forma segura. "
        "Sempre faça: localizar JSON, rodar piloto, rodar dry-run, ler relatório. "
        "NUNCA execute commit, promote ou rollback sem pedir aprovação explícita ao usuário."
    )

    response = client.responses.create(
        model=MODEL,
        input=user_goal,
        tools=TOOLS,
    )

    while True:
        tool_calls = [item for item in response.output if item.type == "function_call"]
        if not tool_calls:
            print(response.output_text)
            break

        tool_outputs = []
        for call in tool_calls:
            args = json.loads(call.arguments or "{}")
            result = dispatch(call.name, args)
            tool_outputs.append({
                "type": "function_call_output",
                "call_id": call.call_id,
                "output": json.dumps(result, ensure_ascii=False),
            })

        response = client.responses.create(
            model=MODEL,
            previous_response_id=response.id,
            input=tool_outputs,
            tools=TOOLS,
        )

if __name__ == "__main__":
    main()