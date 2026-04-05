import os
from openai import OpenAI

print("OPENAI_ORG_ID =", os.getenv("OPENAI_ORG_ID"))
print("OPENAI_PROJECT =", os.getenv("OPENAI_PROJECT"))
print("OPENAI_PROJECT_ID =", os.getenv("OPENAI_PROJECT_ID"))

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

resp = client.responses.create(
    model="gpt-4o-mini",
    input="Responda apenas: ETL pronto para rodar"
)

print(resp.output_text)