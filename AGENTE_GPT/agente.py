import os

while True:
    comando = input("O que fazer? ")

    if comando == "rodar etl":
        os.system("python etl_telegram_rede_optica.py")

    elif comando == "abrir excel":
        os.system("start excel")

    elif comando == "sair":
        break

    else:
        print("Comando desconhecido")