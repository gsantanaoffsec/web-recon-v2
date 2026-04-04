# webrecon.sh

Script bash para reconhecimento ativo de arquivos e diretórios em aplicações web via força bruta com wordlists. Ideal para CTFs e pentests autorizados em ambientes Apache/Ubuntu.

## Dependências

```bash
# Debian/Ubuntu/Kali
sudo apt install curl

# macOS
brew install curl
```

## Wordlists necessárias

O script precisa de dois arquivos no **mesmo diretório** que ele:

| Arquivo | Conteúdo |
|---|---|
| `ldiretorios_formatado.txt` | Um diretório por linha (`admin`, `uploads`, `backup`...) |
| `lista-arq-formatado.txt` | Um nome de arquivo por linha, sem extensão (`config`, `flag`, `senha`...) |

Linhas começando com `#` são ignoradas.

## Uso

```bash
chmod +x webrecon.sh

./webrecon.sh [-a "User-Agent"] <URL> <EXTENSAO>
```

### Exemplos

```bash
# Buscar arquivos .php
./webrecon.sh http://alvo.com .php

# Buscar arquivos sem extensão (arquivo puro, sem .php/.txt/etc)
./webrecon.sh http://alvo.com ''

# Modo coringa: testa ~20 extensões por entrada da wordlist
./webrecon.sh http://alvo.com '*'

# Com User-Agent customizado
./webrecon.sh -a "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" http://alvo.com .php

# Sem extensão + User-Agent customizado
./webrecon.sh -a "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" http://alvo.com ''
```

> **Atenção:** ao usar o modo coringa, sempre use aspas simples em torno do asterisco para evitar que o shell expanda para nomes de arquivos do diretório atual.
>
> ```bash
> # ERRADO - o shell expande * para arquivos do diretório
> ./webrecon.sh http://alvo.com *
>
> # CORRETO - aspas simples preservam o * como literal
> ./webrecon.sh http://alvo.com '*'
> ```

## Extensões testadas no modo coringa

`.php` `.html` `.htm` `.txt` `.js` `.json` `.xml` `.conf` `.config` `.bak` `.old` `.log` `.env` `.py` `.rb` `.pl` `.sh` `.asp` `.aspx` `.jsp`

## Saída

Resultados aparecem em tempo real no terminal, coloridos por tipo:

```
[DIR]  Encontrado: http://alvo.com/admin/
[DIR]  Encontrado: http://alvo.com/uploads/
[ARQ]  Encontrado: http://alvo.com/config.php
[ARQ]  Encontrado: http://alvo.com/.env
```

## Flags

| Flag | Descrição |
|---|---|
| `-a "User-Agent"` | Define um User-Agent customizado. Padrão: `Mozilla/5.0 (Windows NT 10.0; Win64; x64)` |

## Como funciona

O script roda dois rounds em paralelo com até **30 jobs simultâneos**:

1. **Round de diretórios** — testa cada entrada de `ldiretorios_formatado.txt` como `http://alvo.com/entrada/` e registra os que retornam `200`
2. **Round de arquivos** — para cada entrada de `lista-arq-formatado.txt`, testa com cada extensão configurada

A deduplicação usa `flock` para evitar race conditions entre os processos paralelos.

---

> Este script foi desenvolvido para fins educacionais e de segurança ofensiva autorizada. Use apenas em sistemas que você tem permissão explícita para testar.

--------------------------------------------------------------------------------------------------------------------------------------------------------------

# webrecon.sh

A bash script for active reconnaissance of files and directories in web applications via wordlist brute force. Ideal for CTFs and authorized pentests on Apache/Ubuntu environments.

## Dependencies

```bash
# Debian/Ubuntu/Kali
sudo apt install curl

# macOS
brew install curl
```

## Required Wordlists

The script needs two files in the **same directory**:

| File | Content |
|---|---|
| `ldiretorios_formatado.txt` | One directory per line (`admin`, `uploads`, `backup`...) |
| `lista-arq-formatado.txt` | One filename per line, without extension (`config`, `flag`, `passwd`...) |

Lines starting with `#` are ignored.

## Usage

```bash
chmod +x webrecon.sh

./webrecon.sh [-a "User-Agent"] <URL> <EXTENSION>
```

### Examples

```bash
# Search for .php files
./webrecon.sh http://target.com .php

# Search for files with no extension (pure files, no .php/.txt/etc)
./webrecon.sh http://target.com ''

# Wildcard mode: tests ~20 extensions per wordlist entry
./webrecon.sh http://target.com '*'

# With custom User-Agent
./webrecon.sh -a "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" http://target.com .php

# No extension + custom User-Agent
./webrecon.sh -a "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" http://target.com ''
```

> **Important:** when using wildcard mode, always wrap the asterisk in single quotes to prevent the shell from expanding it into local filenames.
>
> ```bash
> # WRONG - the shell expands * into filenames from the current directory
> ./webrecon.sh http://target.com *
>
> # CORRECT - single quotes preserve * as a literal character
> ./webrecon.sh http://target.com '*'
> ```

## Extensions tested in wildcard mode

`.php` `.html` `.htm` `.txt` `.js` `.json` `.xml` `.conf` `.config` `.bak` `.old` `.log` `.env` `.py` `.rb` `.pl` `.sh` `.asp` `.aspx` `.jsp`

## Output

Results appear in real time in the terminal, color-coded by type:

```
[DIR]  Found: http://target.com/admin/
[DIR]  Found: http://target.com/uploads/
[ARQ]  Found: http://target.com/config.php
[ARQ]  Found: http://target.com/.env
```

## Flags

| Flag | Description |
|---|---|
| `-a "User-Agent"` | Sets a custom User-Agent. Default: `Mozilla/5.0 (Windows NT 10.0; Win64; x64)` |

## How it works

The script runs two rounds in parallel with up to **30 simultaneous jobs**:

1. **Directory round** — tests each entry from `ldiretorios_formatado.txt` as `http://target.com/entry/` and records those returning `200`
2. **File round** — for each entry in `lista-arq-formatado.txt`, tests with every configured extension

Deduplication uses `flock` to prevent race conditions between parallel processes.

---

> This script was developed for educational purposes and authorized offensive security only. Use it exclusively on systems you have explicit permission to test.
