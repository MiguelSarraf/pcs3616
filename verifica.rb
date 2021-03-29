#!/usr/bin/env ruby

MEM = <<-STR
0700:  30  00  47  0c  67  0e  97  0a  c7  08  00  08  00  02  00  04  
0710:  00  00  
Final do dump.
STR

def check_ex_job
  file = ".ex/mbs_test_lo_ex.mem"

  if !File.exist?(file)
    puts "[erro] Arquivo #{file} não existe"
    return false
  end

  contents = File.read(file)

  if contents.strip == MEM.strip
    puts "[OK] Ex. 1 (Job EX) está correto"
    return true
  else
    puts "[Incorreto] Ex. 1 (Job EX) incorreto."
    puts
    puts "Obtido:"
    puts contents.strip
    puts
    puts "Esperado:"
    puts MEM.strip
    return false
  end
end

puts
puts "Verificando resultado da execução do MBS..."
puts

check_ex_job
