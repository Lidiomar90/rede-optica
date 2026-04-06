# IA Hub

Este diretório funciona como centro operacional para múltiplas IAs no projeto Rede Óptica MG.

## Estrutura

- `inbox/`
  - avisos e chamadas de nova tarefa
- `fila/`
  - uma pasta por tarefa gerada
- `sessoes/`
  - sessões completas criadas pelo orquestrador multi-IA
- `estado/`
  - estado resumido do hub
- `logs/`
  - logs de execução

## Fluxo

1. Rodar:
   - `C:\FIBRA CADASTRO\ORQUESTRAR-EXECUCAO-IAS.ps1`
2. Enviar os arquivos de entrada para Claude, Gemini, DeepSeek e Manus
3. Colar as respostas em `respostas/` da sessão
4. Consolidar:
   - `C:\FIBRA CADASTRO\CONSOLIDAR-RETORNOS-IAS.ps1 -Sessao "<pasta da sessão>"`
5. Monitorar e resumir automaticamente:
   - `C:\FIBRA CADASTRO\MONITORAR-HUB-IAS.ps1`
6. Opcionalmente publicar se tudo estiver seguro:
   - `C:\FIBRA CADASTRO\MONITORAR-HUB-IAS.ps1 -PublicarSeSeguro`

## Objetivo

Manter:
- contexto único
- papéis claros por IA
- rastreabilidade
- consolidação de decisões
- continuidade operacional do projeto
- e publicação automática com trava básica de segurança
