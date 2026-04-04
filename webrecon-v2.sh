#!/bin/bash

URL=$1
EXTENSAO=$2
MAX_JOBS=30
JOB_COUNT=0
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parsing de flags
while getopts ":a:" opt; do
    case $opt in
        a) USER_AGENT="$OPTARG" ;;
        \?) echo "Opção inválida: -$OPTARG" && exit 1 ;;
        :) echo "A opção -$OPTARG requer um argumento." && exit 1 ;;
    esac
done
shift $((OPTIND - 1))

URL=$1
EXTENSAO=$2

if [ -z "$URL" ]; then
    echo "Uso: $0 [-a \"User-Agent\"] <URL> <EXTENSAO>"
    echo ""
    echo "Exemplos:"
    echo "  $0 http://alvo.com .php"
    echo "  $0 http://alvo.com ''"
    echo "  $0 http://alvo.com '*'"
    echo "  $0 -a \"Mozilla/5.0 Firefox\" http://alvo.com .php"
    exit 1
fi

# Lista de extensões a testar
if [ "$EXTENSAO" == "*" ]; then
    EXTENSOES=("" ".php" ".html" ".htm" ".txt" ".js" ".json" ".xml"
                ".conf" ".config" ".bak" ".old" ".log" ".env"
                ".py" ".rb" ".pl" ".sh" ".asp" ".aspx" ".jsp")
    echo -e "${YELLOW}[*] Modo coringa: testando ${#EXTENSOES[@]} extensões por arquivo${NC}"
elif [ -z "$EXTENSAO" ] || [ "$EXTENSAO" == "''" ] || [ "$EXTENSAO" == '""' ]; then
    EXTENSOES=("")
    echo -e "${YELLOW}[*] Modo sem extensão${NC}"
else
    EXTENSOES=("$EXTENSAO")
    echo -e "${YELLOW}[*] Extensão: $EXTENSAO${NC}"
fi

echo -e "${YELLOW}[*] User-Agent: $USER_AGENT${NC}"

ENCONTRADOS=$(mktemp)
trap "rm -f $ENCONTRADOS" EXIT

export URL
export USER_AGENT
export ENCONTRADOS
export -a EXTENSOES

testar_diretorio() {
    local dir=$1
    local alvo="$URL/$dir/"
    local resposta=$(curl -s \
        -H "User-Agent: $USER_AGENT" \
        --connect-timeout 5 \
        --max-time 10 \
        -o /dev/null \
        -w "%{http_code}" \
        "$alvo")

    if [ "$resposta" == "200" ]; then
        # Deduplicação com flock para evitar race condition entre jobs paralelos
        (
            flock 200
            if ! grep -qxF "$alvo" "$ENCONTRADOS"; then
                echo "$alvo" >> "$ENCONTRADOS"
                echo -e "\033[0;32m[DIR]  Encontrado: $alvo\033[0m"
            fi
        ) 200>"$ENCONTRADOS.lock"
    fi
}

testar_arquivo() {
    local arq=$1

    for ext in "${EXTENSOES[@]}"; do
        if [ -z "$ext" ]; then
            local alvo="$URL/$arq"
        else
            local alvo="$URL/$arq$ext"
        fi

        local resposta=$(curl -s \
            -H "User-Agent: $USER_AGENT" \
            --connect-timeout 5 \
            --max-time 10 \
            -o /dev/null \
            -w "%{http_code}" \
            "$alvo")

        if [ "$resposta" == "200" ]; then
            (
                flock 200
                if ! grep -qxF "$alvo" "$ENCONTRADOS"; then
                    echo "$alvo" >> "$ENCONTRADOS"
                    echo -e "\033[0;36m[ARQ]  Encontrado: $alvo\033[0m"
                fi
            ) 200>"$ENCONTRADOS.lock"
        fi
    done
}

export -f testar_diretorio
export -f testar_arquivo

# Busca de diretórios (paralela)
echo "==> Procurando diretórios..."
while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [[ "$dir" == \#* ]] && continue

    testar_diretorio "$dir" &
    JOB_COUNT=$((JOB_COUNT + 1))
    if [ "$JOB_COUNT" -ge "$MAX_JOBS" ]; then
        wait
        JOB_COUNT=0
    fi
done < ldiretorios_formatado.txt
wait

# Busca de arquivos

echo "==> Procurando arquivos..."
JOB_COUNT=0
while IFS= read -r arq; do
    [ -z "$arq" ] && continue
    [[ "$arq" == \#* ]] && continue

    testar_arquivo "$arq" &
    JOB_COUNT=$((JOB_COUNT + 1))
    if [ "$JOB_COUNT" -ge "$MAX_JOBS" ]; then
        wait
        JOB_COUNT=0
    fi
done < lista-arq-formatado.txt
wait

echo "==> Busca concluída."
