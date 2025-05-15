# lib/bddgenx/cli.rb
require 'fileutils'
require_relative 'parser'
require_relative 'generator'
require_relative 'steps_generator'
require_relative 'validator'
require_relative 'backup'
require_relative 'pdf_exporter'

module Bddgenx
  class Runner
    # Retorna lista de arquivos .txt em input/ ou só aqueles baseados em ARGV
    def self.selecionar_arquivos_txt(input_dir)
      ARGV.map do |arg|
        nome = arg.end_with?('.txt') ? arg : "#{arg}.txt"
        path = File.join(input_dir, nome)
        unless File.exist?(path)
          warn "⚠️  Arquivo não encontrado: #{path}"
          next
        end
        path
      end.compact
    end

    # Interativo: permite ao usuário escolher entre os .txt em input/
    def self.choose_input(input_dir)
      files = Dir.glob(File.join(input_dir, '*.txt'))
      if files.empty?
        warn "❌ Não há arquivos .txt no diretório #{input_dir}"
        exit 1
      end

      puts "Selecione o arquivo de história para processar:"
      files.each_with_index do |f, i|
        puts "#{i+1}. #{File.basename(f)}"
      end
      print "Digite o número correspondente (ou ENTER para todos): "
      choice = STDIN.gets.chomp

      return files if choice.empty?

      idx = choice.to_i - 1
      unless idx.between?(0, files.size - 1)
        warn "❌ Escolha inválida."
        exit 1
      end
      [files[idx]]
    end

    def self.execute
      history_dir = 'input'
      Dir.mkdir(history_dir) unless Dir.exist?(history_dir)

      # Determina quais arquivos processar
      arquivos = if ARGV.any?
                   selecionar_arquivos_txt(history_dir)
                 else
                   choose_input(history_dir)
                 end

      if arquivos.empty?
        warn "❌ Nenhum arquivo de história para processar."
        exit 1
      end

      # Contadores e coleções
      total = features = steps = ignored = 0
      skipped_steps = []
      generated_pdfs = []
      skipped_pdfs = []

      arquivos.each do |arquivo|
        total += 1
        puts "\n🔍 Processando: #{arquivo}"

        historia = Parser.ler_historia(arquivo)
        unless Validator.validar(historia)
          ignored += 1
          puts "❌ Arquivo inválido: #{arquivo}"
          next
        end

        # Geração de feature
        feature_path, feature_content = Generator.gerar_feature(historia)
        Backup.salvar_versao_antiga(feature_path)
        if Generator.salvar_feature(feature_path, feature_content)
          features += 1
        end

        # Geração de steps
        if StepsGenerator.gerar_passos(feature_path)
          steps += 1
        else
          skipped_steps << feature_path
        end

        # Exportação de PDFs
        FileUtils.mkdir_p('reports')
        results = PDFExporter.exportar_todos(only_new: true)
        generated_pdfs.concat(results[:generated])
        skipped_pdfs.concat(results[:skipped])
      end

      # Resumo final
      puts "\n✅ Processamento concluído"
      puts "- Total de histórias:    #{total}"
      puts "- Features geradas:      #{features}"
      puts "- Steps gerados:         #{steps}"
      puts "- Steps ignorados:       #{skipped_steps.size}"
      puts "- PDFs gerados:          #{generated_pdfs.size}"
      puts "- PDFs já existentes:    #{skipped_pdfs.size}"
      puts "- Arquivos ignorados:    #{ignored}"
    end
  end
end
