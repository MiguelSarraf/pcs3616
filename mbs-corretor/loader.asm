; -------------------------------------------------------------------
; Loader
; -------------------------------------------------------------------

; Símbolos exportados
; -------------------------------------------------------------------
>           LOADER   
>           LOADER_UL

; Origem relocável
                &       /0000

; Constantes
UM           K          /0001
DOIS         K          /0002
GD_OP        K          /D300
SAVE_OP      K          /9000
END_LIMITE   K          /0FFF
ERROR_TAM    K          /FFFE
ERROR_SUM    K          /FFFC

; Variáveis
END_INICIAL  $          /0001
TAM          $          /0001
DOIS_TAM     $          /0001
COUNT        $          /0001
COUNT2       $          /0001
COUNT3       $          /0001
DADO_LIDO    $          /0001
CHECKSUM     $          /0001

; Parâmetros
LOADER_UL    $          /0001
LOADER       $          /0001

             LD         GD_OP
             AD         LOADER_UL
             MM         DO_GD_1
             MM         DO_GD_2
             MM         DO_GD_3
             MM         DO_GD_4
             MM         DO_GD_5
             MM         FIM2
             MM         SAI_NORMAL

; Load da posição inicial e do tamanho
DO_GD_1      $          /0001
             MM         END_INICIAL
DO_GD_2      $          /0001
             MM         TAM
             ML         DOIS
             MM         DOIS_TAM

; Cálculo de erro
             LD         END_LIMITE
             SB         END_INICIAL
             AD         UM
             SB         DOIS_TAM
             JN         SAI_ERROR_TAM

; Cabe na memória, então: loop
                LV      /0000
                MM      COUNT
LOOP            LD      COUNT
                SB      DOIS_TAM
                JZ      SAI_NORMAL
                LV      /0000
                MM      CHECKSUM
DO_GD_3         $       /0001                 ; Endereço inicial
                MM      END_INICIAL
                AD      CHECKSUM
                MM      CHECKSUM
DO_GD_4         $       /0001                 ; Tamanho do bloco
                MM      COUNT2
                MM      COUNT3
                AD      CHECKSUM
                MM      CHECKSUM
                LD      COUNT2
                ML      DOIS
                AD      COUNT
                MM      COUNT
LOOP2           LD      COUNT2
                JZ      FIM2
                LD      COUNT3                ; Calcula endereço de leitura
                SB      COUNT2
                ML      DOIS
                AD      END_INICIAL
                AD      SAVE_OP
                MM      SAVE_DATA
DO_GD_5         $       /0001
SAVE_DATA       $       /0001
                AD      CHECKSUM
                MM      CHECKSUM
                LD      COUNT2
                SB      UM
                MM      COUNT2
                JP      LOOP2
FIM2            $       /0001                 ; Verifica checksum
                SB      CHECKSUM
                JZ      SUM_OK
                JP      WRONGSUM
SUM_OK          JP      LOOP
WRONGSUM        LD      ERROR_SUM
                RS      LOADER
SAI_ERROR_TAM   LD      ERROR_TAM
                RS      LOADER
SAI_NORMAL      $       /0001
                RS      LOADER

# LOADER
