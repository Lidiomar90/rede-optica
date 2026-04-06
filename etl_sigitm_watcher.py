import os, sys, time, pandas as pd, json, uuid
from pathlib import Path

# Configurações de Pastas
WATCH_DIR = Path("C:/FIBRA CADASTRO/import_sigitm")
PROCESSED_DIR = WATCH_DIR / "processados"
WATCH_DIR.mkdir(exist_ok=True)
PROCESSED_DIR.mkdir(exist_ok=True)

def processar_arquivo_sigitm(file_path):
    print(f"🔍 Analisando arquivo: {file_path.name}")
    try:
        # Tenta ler Excel ou CSV
        if file_path.suffix in ['.xlsx', '.xls']:
            df = pd.read_excel(file_path)
        else:
            df = pd.read_csv(file_path, sep=';', encoding='latin1')

        eventos = []
        for _, row in df.iterrows():
            # Mapeamento robusto para colunas reais do SIGITM
            ta = str(row.get('Sequencia', row.get('Ticket', row.get('TA', ''))))
            causa = str(row.get('Baixa Causa', row.get('Causa', 'Não informada')))
            site = str(row.get('Código Site', row.get('Sigla Site V2', row.get('Site', ''))))
            end = str(row.get('Endereço falha Óptica', row.get('Endereço', '')))
            
            lat = row.get('Latitude Falha')
            lon = row.get('Longitude Falha')
            coord = f"{lat},{lon}" if pd.notnull(lat) and pd.notnull(lon) else str(row.get('Coordenadas', ''))

            evento = {
                "id_externo": str(uuid.uuid4()),
                "numero_ta": ta,
                "causa_falha": causa,
                "site_afetado": site,
                "endereco": end,
                "coordenadas_brutas": coord,
                "status_validacao": "pendente_supervisor",
                "data_importacao": time.strftime('%Y-%m-%d %H:%M:%S'),
                "detalhes": str(row.get('Descrição da Baixa', ''))
            }
            if ta and ta != 'nan':
                eventos.append(evento)

        # Salva um JSON temporário para o Front-end ler como "Fila de Aprovação"
        # Em um cenário real, isso iria para a tabela stg_sigitm no Supabase
        output_file = Path("C:/FIBRA CADASTRO/sigitm_pendentes.json")
        existente = []
        if output_file.exists():
            with open(output_file, 'r', encoding='utf-8') as f:
                existente = json.load(f)
        
        # Evitar duplicados por TA e limitar tamanho para performance do front
        tas_existentes = {str(e['numero_ta']) for e in existente}
        novos = [e for e in eventos if str(e['numero_ta']) not in tas_existentes]
        
        final = (novos + existente)[:500] 
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(final, f, indent=2, ensure_ascii=False)

        print(f"✅ {len(novos)} novos eventos enviados para fila de aprovação.")
        
        # Move arquivo para processados
        file_path.replace(PROCESSED_DIR / file_path.name)

    except Exception as e:
        print(f"❌ Erro ao processar: {e}")

if __name__ == "__main__":
    print(f"🚀 Monitorando {WATCH_DIR}...")
    while True:
        arquivos = [f for f in WATCH_DIR.iterdir() if f.is_file() and f.suffix in ['.xlsx', '.xls', '.csv']]
        for arq in arquivos:
            processar_arquivo_sigitm(arq)
        time.sleep(10)
