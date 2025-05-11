require_relative "bddgenx/version"
require_relative "bddgenx/parser"
require_relative "bddgenx/generator"
require_relative "bddgenx/cli"
require_relative "bddgenx/validator"
require_relative "bddgenx/steps_generator"
require_relative "bddgenx/tracer"
require_relative "bddgenx/backup"
require_relative 'bddgenx/pdf_exporter'


cont_total = 0
cont_features = 0
cont_steps = 0
cont_ignorados = 0

# Exibe menu inicial e pergunta quais arquivos processar
arquivos = CLI.selecionar_arquivos_txt('input')

arquivos.each do |arquivo_path|
 puts "\n🔍 Processando: #{arquivo_path}"

  historia = Parser.ler_historia(arquivo_path)

  unless Validator.validar(historia)
    cont_ignorados += 1
    puts "❌ Arquivo inválido: #{arquivo_path}"
    next
  end

  nome_feature, conteudo_feature = Generator.gerar_feature(historia)

  Backup.salvar_versao_antiga(nome_feature)
  cont_features += 1 if Generator.salvar_feature(nome_feature, conteudo_feature)
  cont_steps += 1 if StepsGenerator.gerar_passos(historia, nome_feature)

 Tracer.adicionar_entrada(historia, nome_feature)
 Bddgenx::PDFExporter.exportar_todos
end
puts "\n✅ Processamento finalizado. Arquivos gerados em: features/, steps/, output/"
puts "🔄 Versões antigas salvas em: backup/"

puts "\n✅ Processamento finalizado:"
puts "- Arquivos processados: #{cont_total}"
puts "- Features geradas:     #{cont_features}"
puts "- Steps gerados:        #{cont_steps}"
puts "- Ignorados:            #{cont_ignorados}"
