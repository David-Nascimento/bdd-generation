require 'rake'
require_relative 'lib/bddgen.rb'
require_relative 'lib/bddgen/pdf_exporter'
require_relative 'lib/bddgen/integrations/jira'
require_relative 'lib/bddgen/integrations/testlink'

namespace :bddgen do

  desc "Gerar arquivos .feature, steps, rastreabilidade e backups"
  task :gerar do
    arquivos = Bddgen::CLI.todos_arquivos('input')
    arquivos.each do |arquivo|
      puts "🔁 Executando: ruby bddgen.rb"
      system("ruby lib/bddgen.rb")
    end

  end

  desc "Exportar todos os arquivos .feature para PDF"
  task :pdf do
    puts "📦 Exportando para PDF..."
    Bddgen::PDFExporter.exportar_todos
  end

  desc "Enviar todos os cenários para o Jira"
  task :jira do
    jira = Bddgen::Integrations::Jira.new(
      username: ENV['JIRA_USER'],
      api_token: ENV['JIRA_TOKEN'],
      site: ENV['JIRA_SITE'],
      project_key: ENV['JIRA_PROJECT']
    )

    Dir.glob("features/*.feature") do |arquivo|
      conteudo = File.read(arquivo)
      titulo = File.basename(arquivo, ".feature").gsub('_', ' ').capitalize
      jira.enviar_cenario(titulo, conteudo)
    end
  end

  desc "Enviar todos os cenários para o TestLink"
  task :testlink do
    testlink = Bddgen::Integrations::TestLink.new(
      ENV['TESTLINK_TOKEN'],
      ENV['TESTLINK_URL']
    )

    Dir.glob("features/*.feature") do |arquivo|
      conteudo = File.readlines(arquivo).reject { |l| l.strip.start_with?("#") || l.strip.empty? }
      titulo = File.basename(arquivo, ".feature").gsub('_', ' ').capitalize
      testlink.criar_caso_teste(ENV['TESTLINK_PLAN_ID'].to_i, titulo, conteudo)
    end
  end
end
