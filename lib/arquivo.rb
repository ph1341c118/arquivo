# frozen_string_literal: true

require 'thor'
require 'arquivo/version'
require 'arquivo/dir'
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

      system "mkdir -p #{f.base}"
      f.processa_minuta(options)
    end

    desc 'pdf EXTRATO', 'processa EXTRATO criando pasta ' \
                        'com documentos para arquivo'
    def pdf(file)
      return unless File.exist?(file) && File.ftype(file) == 'file'

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

    desc 'dir PASTA', 'processa faturas/recibos/extratos/minutas ' \
                      ' e cria arquivos c118'
    option :fuzz, type: :numeric, default: 29,
                  desc: 'fuzz trim jpg N-1, escolhe menor -> scanned pdf'
    option :quality, type: :numeric, default: 15,
                     desc: 'compress jpg N% -> scanned pdf (less=low quality)'

    option :noise, type: :boolean, default: false,
                   desc: 'ruido de fundo - sim ou nao'
    option :sound, type: :numeric, default: 1.0,
                   desc: 'minimo som que determina fim do silencio (segundos)'
    option :amount, type: :numeric, default: 0.0001,
                    desc: 'qtd ruido a ser removido'
    option :rate, type: :numeric, default: 16,
                  desc: 'sample rate - radio-16k, CD-44.1k, PC-48k, pro-96k'

    def dir(fdir)
      return unless File.ftype(fdir) == 'directory'

      C118dir.new(fdir).processa_pasta(fdir, options)
    end
  end
end
