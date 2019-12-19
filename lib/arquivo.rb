# frozen_string_literal: true

require 'thor'
require 'arquivo/version'
require 'arquivo/extrato'
require 'arquivo/dir'
require 'arquivo/noise'
require 'arquivo/pdf'
require 'arquivo/jpg'
require 'arquivo/mp3'

module Arquivo
  class Error < StandardError; end

  # CLI para analisar/processar documentos c118
  class CLI < Thor
    desc 'mp3 MINUTA', 'processa MINUTA criando pasta ' \
                       'com segmentos para arquivo'
    option :tempos, type: :array, default: [],
                    desc: 'lista tempos para segmentar MINUTA, ex: [[h:]m:]s'
    def mp3(file)
      return unless File.exist?(file) && File.ftype(file) == 'file'

      f = C118mp3.new(file)
      return unless f.processa_minuta?

      system "mkdir -p tmp #{f.base}"
      f.processa_minuta(options)
    end

    desc 'pdf PDF', 'processa PDF criando pasta com documentos para arquivo'
    def pdf(file)
      return unless File.ftype(file) == 'file'

      f = C118pdf.new(file)
      return unless f.processa_extrato?

      system "mkdir -p #{f.base}"
      # extrato contem conta c118
      if f.extrato?
        f.processa_extrato(0)
      else
        f.split
      end
    end

    desc 'dir PASTA', 'processa faturas/recibos/extratos/minutas'
    option :fuzz, type: :numeric, default: 29,
                  desc: 'fuzz trim jpg N-1, escolhe menor -> scanned pdf'
    option :quality, type: :numeric, default: 15,
                     desc: 'compress jpg N% -> scanned pdf (less=low quality)'
    option :nred, type: :boolean, default: true,
                  desc: 'fazer reducao do ruido de fundo'
    option :som, type: :numeric, default: 1.0,
                 desc: 'minimo som que determina fim do silencio (segundos)'
    option :amount, type: :numeric, default: 0.00001,
                    desc: 'qtd ruido a ser removido'
    def dir(fdir)
      return unless File.ftype(fdir) == 'directory'

      C118dir.new(fdir).prepara(fdir, options).processa_pasta(options)
    end
  end
end
