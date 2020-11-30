#!/bin/bash

# ------------------------------------------------------------------
# PARTE 1: setup

# Aborta o script em caso de erro.
set -e

# Diretório em que este script está.
SELFDIR=$( cd "$(dirname "$0")" ; pwd -P )

# Caso o script tenha sido chamado de outro diretório, vai até
# o diretório do script.
cd ${SELFDIR}

# Importa arquivo com funções auxiliares
source 'utils.sh'

# ------------------------------------------------------------------

ZIPFILE='mbs-parte2.zip'

# ------------------------------------------------------------------

p_info '-------------------------------------------------------------------'
p_info 'Correção do Exercício (Aula 10 - Monitor Batch - Parte II)'
p_info '-------------------------------------------------------------------'

if [[ "$NO_ZIP" ]]; then
  p_info "Corrigindo diretamente do diretório mbs-corretor"
  mkdir -p .ex
else

  # Verifica se o arquivo zip existe.
  if [[ -f "${ZIPFILE}" ]]; then
    p_ok "[Ok] Arquivo ${ZIPFILE} existe"
  else
    p_err "[erro] Arquivo ${ZIPFILE} não existe no diretório: $(pwd)"
    exit 1
  fi

  # Extrai o conteúdo do arquivo.
  rm -rf .ex
  unzip -d .ex ${ZIPFILE}

  # Verifica se o arquivo main.asm existe.
  if [[ -f ".ex/main.asm" ]]; then
    p_ok "[Ok] Arquivo main.asm existe"
  else
    p_err "[erro] Arquivo main.asm não encontrado no arquivo zip (${ZIPFILE})"
    exit 1
  fi

  # Move o arquivo main para o diretório mbs-corretor
  cp .ex/main.asm mbs-source/
fi

# Apaga e recria os diretórios e arquivos usados pelo corretor.
rm -rf .ex
mkdir .ex

if [[ "$MBS_SOURCE_DIR" = "" ]]; then
  MBS_SOURCE_DIR="$SELFDIR/mbs-source"
fi

# Verifica se o diretório com o código-fonte existe.

if [[ -d "$MBS_SOURCE_DIR" ]]; then
  p_ok "[Ok] Diretório com o código-fonte do MBS existe"
else
  p_err "[erro] Diretório com o código-fonte do MBS não existe: $MBS_SOURCE_DIR"
  exit 1
fi

(
  cd $MBS_SOURCE_DIR &&
  rm -f dumper.lst dumper.mvn loader.lst loader.mvn main.lst main.mvn main-absoluto.mvn main-relocavel.mvn
)

# Monta cada arquivo individualmente
python3 ../MLR/montador.py $MBS_SOURCE_DIR/dumper.asm
python3 ../MLR/montador.py $MBS_SOURCE_DIR/loader.asm
python3 ../MLR/montador.py $MBS_SOURCE_DIR/main.asm

# Liga os arquivos
python3 ../MLR/ligador.py $MBS_SOURCE_DIR/main.mvn $MBS_SOURCE_DIR/dumper.mvn $MBS_SOURCE_DIR/loader.mvn $MBS_SOURCE_DIR/main-relocavel.mvn

# Reloca
python3 ../MLR/relocador.py $MBS_SOURCE_DIR/main-relocavel.mvn $MBS_SOURCE_DIR/main-absoluto.mvn 0000

# -------------------------------------------------------------------
# Executa teste de LO e EX na MVN
# -------------------------------------------------------------------

mvn_cmd='python3 ../MVN/mvnMonitor.py'

set +e

echo -e "p $MBS_SOURCE_DIR/main-absoluto.mvn
p mbs_clean.mvn
r \n\nn\n\n
m 0700 0711 .ex/mbs_test_lo_ex.mem
x" | ${mvn_cmd} > $SELFDIR/.ex/mbs_test_lo_ex.stdout

ruby verifica.rb