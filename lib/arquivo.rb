# frozen_string_literal: true

require 'thor'
require 'arquivo/version'
require 'arquivo/dir'
require 'arquivo/pdf'
require 'arquivo/jpg'
require 'arquivo/mp3'

# @author Hernani Rodrigues Vaz
# processa documentos do condominio ph1341c118 para arquivo;
# pode tambem segmentar PDFs e MINUTAS;
# tendo os documentos em pastas separadas,
# pode ainda criar arquivos apropriados.
module Arquivo
  class Error < StandardError; end

  # @abstract CLI tarefas segmentar e arquivar
  class CLI < Thor
    desc 'mp3 MINUTA', 'processa MINUTA criando pasta ' \
                       'com segmentos para arquivo'
    option :tempos, type: :array, default: [],
                    desc: 'lista tempos para segmentar MINUTA, ex: [[h:]m:]s'
    # segmenta minuta segundo lista tempos
    #
    # @param [String] minuta ficheiro audio a segmentar
    def mp3(minuta)
      return unless File.exist?(minuta) && File.ftype(minuta) == 'file'

      f = C118mp3.new(minuta, options)
      return unless f.segmenta_minuta?

      system "mkdir -p #{f.base}"
      f.segmenta_minuta(options[:tempos])
    end

    desc 'pdf EXTRATO', 'processa EXTRATO criando pasta ' \
                        'com documentos para arquivo'
    # segmenta extrato limpando publicidade
    #
    # @param [String] extrato pdf a segmentar
    def pdf(extrato)
      return unless File.exist?(extrato) && File.ftype(extrato) == 'file'

      f = C118pdf.new(extrato, options)
      return unless f.processa_extrato?

      system "mkdir -p #{f.base}"
      # extrato contem conta c118
      if f.pagina_extrato?
        f.processa_extrato(0)
      else
        f.split
      end
    end

    desc 'dsh DASHBOARD', 'processa DASHBOARD criando pdf c118'
    # cria DASHBOARD c118
    #
    # @param [String] dashboard pdf a processar
    def dsh(dashboard)
      return unless File.exist?(dashboard) && File.ftype(dashboard) == 'file'

      C118pdf.new(dashboard, options).faz_dashboard
    end

    desc 'big', 'processa dados bigquery c118'
    # processa bigquery c118
    def big
      C118dir.new('/home/c118', options).processa_big
    end

    desc 'dir PASTA', 'processa faturas/recibos/extratos/minutas ' \
                      'e cria arquivos c118'
    option :fuzz, type: :numeric, default: 29,
                  desc: 'fuzz trim jpg N-1, escolhe menor -> scanned pdf'
    option :quality, type: :numeric, default: 15,
                     desc: 'compress jpg N% -> scanned pdf (less=low quality)'

    option :threshold, type: :numeric, default: 9,
                       desc: 'limiar maximo para silencio, 0% = silencio puro'
    option :sound, type: :numeric, default: 1,
                   desc: 'segundos de som para terminar silencio'

    option :amount, type: :numeric, default: 0.00001,
                    desc: 'qtd ruido a ser removido'
    option :rate, type: :numeric, default: 16,
                  desc: 'sample rate - radio-16k, CD-44.1k, PC-48k, pro-96k'
    # arquiva pasta de documentos c118
    #
    # @param [String] pasta contem os documentos para arquivar
    def dir(pasta)
      return unless File.ftype(pasta) == 'directory'

      C118dir.new(pasta, options).processa_pasta
    end
  end
end
