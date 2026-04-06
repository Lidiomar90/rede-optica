#!/usr/bin/env python3
"""
Gera uma base deduplicada de sites MG a partir da planilha Science e,
opcionalmente, envia os registros para o Supabase.

Uso:
  python importar_science.py
  python importar_science.py --supabase
  python importar_science.py --json-path outro_arquivo.json
"""
import argparse
import json
import math
import os
import sys
import urllib.request

import pandas as pd

XLS_PATH = r"C:\FIBRA CADASTRO\Consulta_Science_-_Site_01_10_25_V1.xls"
JSON_PATH = r"C:\FIBRA CADASTRO\science_sites_mg.json"
SHEET_NAME = "SITE"
SB_URL = "https://xmqxhzmjxprhvyqwlqvz.supabase.co"
SB_KEY = os.getenv("SB_KEY", "")
BATCH = 300


def safe_float(value):
    text = str(value).strip()
    if not text or text.lower() == "nan":
        return None
    try:
        if "," in text and "." in text:
            text = text.replace(".", "").replace(",", ".")
        elif "," in text:
            text = text.replace(",", ".")
        num = float(text)
        return None if math.isnan(num) else num
    except Exception:
        return None


def clean_text(value):
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return None
    text = str(value).strip()
    return text or None


def clean_cn(value):
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return None
    try:
        num = float(value)
        if num.is_integer():
            return str(int(num))
    except Exception:
        pass
    return clean_text(value)


def map_status(value):
    text = (clean_text(value) or "").upper()
    if "ATIVO" in text:
        return "ativo"
    if "CANCEL" in text or "DISTRAT" in text or "DESATIV" in text:
        return "inativo"
    return "previsto"


def read_science_sheet(path):
    last_error = None
    for kwargs in ({}, {"engine": "openpyxl"}, {"engine": "xlrd"}):
        try:
            return pd.read_excel(path, sheet_name=SHEET_NAME, **kwargs)
        except Exception as exc:
            last_error = exc
    raise last_error


def build_records(df):
    mg = df[df["SIG_ESTADO"].astype(str).str.upper().eq("MG")].copy()
    mg["lat"] = mg["STR_LATITUDE_SITE"].apply(safe_float)
    mg["lng"] = mg["STR_LONGITUDE_SITE"].apply(safe_float)
    mg = mg[
        mg["lat"].notna()
        & mg["lng"].notna()
        & mg["lat"].between(-35, -5)
        & mg["lng"].between(-75, -33)
    ].copy()
    mg["codigo_norm"] = mg["SIG_SITE"].astype(str).str.strip().str.upper()
    mg = mg[mg["codigo_norm"].str.len() >= 2].copy()
    mg.sort_values(
        by=["codigo_norm", "SITUACAO", "DTC_CADASTRO"],
        ascending=[True, True, False],
        inplace=True,
    )
    mg = mg.drop_duplicates(subset=["codigo_norm"], keep="first")

    records = []
    for row in mg.to_dict("records"):
        codigo = row["codigo_norm"]
        lat = row["lat"]
        lng = row["lng"]
        records.append(
            {
                "codigo": codigo,
                "seq_site": clean_text(row.get("SEQ_SITE")),
                "cn": clean_cn(row.get("CN")),
                "nome": clean_text(row.get("NOM_SITE")) or codigo,
                "municipio": clean_text(row.get("NOM_MUNICIPIO")),
                "localidade": clean_text(row.get("NOM_LOCALIDADE")),
                "uf": "MG",
                "status": map_status(row.get("SITUACAO")),
                "situacao_raw": clean_text(row.get("SITUACAO")),
                "supervisor": clean_text(row.get("SUPERVISOR")),
                "endereco": clean_text(row.get("DES_ENDERECO_SITE")),
                "endereco_ssi": clean_text(row.get("DES_ENDERECO_SITE_SSI")),
                "cep": clean_text(row.get("STR_CEP_SITE")),
                "id_financeiro": clean_text(row.get("STR_ID_FINANCEIRO")),
                "tipo_site": clean_text(row.get("STR_TIPO_SITE")),
                "descricao_tipo_site": clean_text(row.get("DES_TIPO_SITE")),
                "categoria_site": clean_text(row.get("CATEGORIA_SITE")),
                "subcategoria_site": clean_text(row.get("SUB_CATEGORIA_SITE")),
                "tipo_estrutura": clean_text(row.get("TIPO_ESTRUTURA")),
                "tipo_construcao": clean_text(row.get("DES_TIPO_CONSTRUCAO")),
                "modo_contrato": clean_text(row.get("DES_MODO_CONTRATO")),
                "pessoa": clean_text(row.get("NOM_PESSOA")),
                "solicitante": clean_text(row.get("NOM_SOLICITANTE")),
                "cedente": clean_text(row.get("NOM_CEDENTE")),
                "site_vip": clean_text(row.get("SITE_VIP")),
                "restricao_acesso": clean_text(row.get("STS_RESTRICAO_ACESSO")),
                "tipo_restricao": clean_text(row.get("TIPO RESTRIÇÃO")),
                "detentora": clean_text(row.get("NUM_DETENTORA")),
                "concentradora": clean_text(row.get("STN_CONCENTRADORA")),
                "fronteira_internacional": clean_text(row.get("STS_FRONTEIRA_INTERNACIONAL")),
                "configuracao_site": clean_text(row.get("STS_CONFIGURACAO_SITE")),
                "pendente_infra": clean_text(row.get("STN_PENDENTE_INFRA")),
                "criticidade": clean_text(row.get("STS_CRITICO")),
                "science_pendente": clean_text(row.get("STN_SCI_PENDENTE")),
                "data_inicio_operacao": clean_text(row.get("DTC_INICIO_OPERACAO")),
                "data_desativacao": clean_text(row.get("DTC_DESATIVACAO_SITE")),
                "data_aquisicao": clean_text(row.get("DTC_AQUISICAO")),
                "data_distrato": clean_text(row.get("DTC_DISTRATO")),
                "data_cadastro": clean_text(row.get("DTC_CADASTRO")),
                "latitude": lat,
                "longitude": lng,
                "localizacao": {"type": "Point", "coordinates": [lng, lat]},
                "localizacao_wkt": f"SRID=4326;POINT({lng} {lat})",
                "fonte": "science",
            }
        )
    return records


def export_json(records, path):
    payload = {
        "fonte": "Consulta_Science_-_Site_01_10_25_V1",
        "total_sites": len(records),
        "cns": sorted({r["cn"] for r in records if r.get("cn")}, key=lambda x: (len(str(x)), str(x))),
        "sites": records,
    }
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)


def post_batch(payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        f"{SB_URL}/rest/v1/sites",
        data=data,
        method="POST",
        headers={
            "apikey": SB_KEY,
            "Authorization": f"Bearer {SB_KEY}",
            "Content-Type": "application/json",
            "Prefer": "return=minimal",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return response.status
    except urllib.error.HTTPError as exc:
        return exc.code


def upload_supabase(records):
    if not SB_KEY:
        print("ERRO: defina $env:SB_KEY='sua-chave-anon' para enviar ao Supabase")
        return 0, 0, len(records)

    ok = skip = err = 0
    for idx in range(0, len(records), BATCH):
        lote = records[idx : idx + BATCH]
        payload = []
        for site in lote:
            payload.append(
                {
                    "codigo": site["codigo"],
                    "nome": (site["nome"] or site["codigo"])[:300],
                    "tipo": "ERB",
                    "camada": "acesso",
                    "municipio": (site.get("municipio") or "")[:100],
                    "uf": "MG",
                    "status": site.get("status") or "ativo",
                    "qualidade_cadastro": "science_import",
                    "observacao": (
                        f"Science CN {site.get('cn') or '-'} | "
                        f"Localidade {site.get('localidade') or '-'} | "
                        f"Supervisor {site.get('supervisor') or '-'}"
                    )[:500],
                    "localizacao": site["localizacao_wkt"],
                }
            )
        status = post_batch(payload)
        if status in (200, 201):
            ok += len(payload)
        elif status == 409:
            skip += len(payload)
        else:
            err += len(payload)
            print(f"  Lote {idx // BATCH + 1}: status {status}")
        if (idx // BATCH + 1) % 5 == 0:
            print(f"  {ok + skip + err}/{len(records)} | ok={ok} skip={skip} err={err}")
    return ok, skip, err


def parse_args():
    parser = argparse.ArgumentParser(description="Gera base deduplicada de sites Science MG.")
    parser.add_argument("--supabase", action="store_true", help="Envia os sites ao Supabase apos gerar o JSON.")
    parser.add_argument("--json-path", default=JSON_PATH, help="Caminho do JSON gerado.")
    return parser.parse_args()


def main():
    args = parse_args()
    if not os.path.exists(XLS_PATH):
        print(f"ERRO: arquivo não encontrado: {XLS_PATH}")
        sys.exit(1)

    print("Lendo planilha Science...")
    df = read_science_sheet(XLS_PATH)
    records = build_records(df)
    print(f"Sites MG válidos e deduplicados: {len(records)}")
    export_json(records, args.json_path)
    print(f"JSON gerado em: {args.json_path}")

    if args.supabase:
        ok, skip, err = upload_supabase(records)
        print(f"\nConcluído no Supabase: inseridos={ok} | duplicatas={skip} | erros={err}")


if __name__ == "__main__":
    main()
