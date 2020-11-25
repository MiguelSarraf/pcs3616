#!/bin/bash

# ------------------------------------------------------------------
# PARTE 1: Setup

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

ZIPFILE='mbs-parte1.zip'

p_info '-------------------------------------------------------------------'
p_info 'Correção do Exercício (Aula 9 - Monitor Batch)'
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
  cp .ex/main.asm mbs-corretor/
fi

# Apaga arquivos de possíveis execuções anteriores do corretor.

rm -f disp.lst mem-load.dump

(
  cd mbs-corretor &&
  rm -f dump.data dumper.lst dumper.mvn loader.lst loader.mvn log.txt main.lst main.mvn main-absoluto.mvn main-relocavel.mvn
)

# Monta cada arquivo individualmente
python3  ../MLR/montador.py mbs-corretor/dumper.asm
python3  ../MLR/montador.py mbs-corretor/loader.asm
python3  ../MLR/montador.py mbs-corretor/main.asm

# Liga os arquivos
python3 ../MLR/ligador.py mbs-corretor/main.mvn mbs-corretor/dumper.mvn mbs-corretor/loader.mvn mbs-corretor/main-relocavel.mvn

# Reloca
python3 ../MLR/relocador.py mbs-corretor/main-relocavel.mvn mbs-corretor/main-absoluto.mvn 0000

# -------------------------------------------------------------------
# Executa teste de dump na MVN
# -------------------------------------------------------------------

rm -f mbs-corretor/dump.data mbs-corretor/log.txt
rm -f disp.lst
cp disp-dump.lst disp.lst

mvn_cmd='python3 ../MVN/mvnMonitor.py'

echo -e "p mbs-corretor/main-absoluto.mvn
p mbs-corretor/mem-test-dump.mvn
m 0600 0611
r\n\n\n\n
x" | ${mvn_cmd}> '.ex/mvn-test-dump.stdout' 2>&1

# Verifica se o arquivo dump.data existe.
if [[ -f "mbs-corretor/dump.data" ]]; then
  p_ok "[Ok] Arquivo dump.data foi criado"
else
  p_err "[Erro] Arquivo dump.data não foi criado"
  exit 1
fi

# -------------------------------------------------------------------
set +e

cmp_output=$(cmp mbs-corretor/dump.data mbs-corretor/dump.ref)
return_code=$?

if [[ $return_code -ne 0 ]]; then
  p_err "[Erro] Arquivo dump.data não foi gerado corretamente. Verifique a execução no arquivo '.ex/mvn-test-dump.stdout'"
  p_err "\nNota: 0.000"
  exit 1
else
  p_ok "[Ok] Arquivo dump.data foi gerado corretamente (+ 4 pontos)"
fi

set -e
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Executa teste de load na MVN
# -------------------------------------------------------------------

rm -f mbs-corretor/log.txt
rm -f disp.lst
cp disp-load.lst disp.lst

echo -e "p mbs-corretor/main-absoluto.mvn
p mbs-corretor/mem-test-load.mvn
m 0600 0611
r \n\n\n\n
m 0600 0611 mem-load.dump
x" | ${mvn_cmd} > '.ex/mvn-test-load.stdout' 2>&1

# -------------------------------------------------------------------
set +e

cmp_output=$(cmp mem-load.dump mbs-corretor/load.ref)
return_code=$?

if [[ $return_code -ne 0 ]]; then
  p_err "[Erro] Arquivo não foi carregado na memória corretamente. Verifique a execução no arquivo '.ex/mvn-test-load.stdout'"
  p_err "\nNota: 4.000"
  exit 1
else
  p_ok "[Ok] Arquivo foi carregado na memória corretamente. (+ 4 pontos)"
fi

set -e
# -------------------------------------------------------------------

p_info "Executando MBS para casos de erro"

rm -f disp.lst
cp disp-err.lst disp.lst

results=""

for f in mbs-corretor/casos-erro/*.txt ; do

  rm -f mbs-corretor/log.txt

  cp $f mbs-corretor/batch-err.txt

  filename=$(basename "$f")
  filename="${filename%.*}"

  echo -e "p mbs-corretor/main-absoluto.mvn
r\n\nn\n\n
x" | ${mvn_cmd} > '.ex/mvn-test-err.stdout' 2>&1

  cp mbs-corretor/log.txt .ex/log-err-$filename.txt

  expected=$(tail -1 $f)
  actual=$(cat mbs-corretor/log.txt)

  set +e

  echo $expected | grep -P '^ER' >/dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    expected='ER:END'
  fi

  set -e

  if [[ "$expected" = "$actual" ]]; then
    p_ok "[Ok] Caso de teste $(basename $f) correto"
    results="$results 1"
  else
    p_err "[Erro] Caso de teste $(basename $f) incorreto. Esperado: ${expected}. Obtido: ${actual}"
    results="$results 0"
  fi

done

cmd=$(ruby <<EORB
  results = "$results"
  pass = results.scan(/1/).count
  fail = results.scan(/0/).count
  grade = (pass.to_f)/(pass+fail)
  grade > 0.5 ? (puts %Q=p_ok Casos de erro: +#{grade*2} pontos=) : (puts %Q=p_err Casos de erro: +#{grade*2} pontos=)
EORB
)

$cmd
