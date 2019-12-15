# frozen_string_literal: true

require 'thor'
require 'arquivo/version'
require 'arquivo/extrato'
require 'arquivo/dir'
require 'arquivo/pdf'
require 'arquivo/jpg'

module Arquivo
  class Error < StandardError; end

  # CLI para analisar/processar documentos c118
  class CLI < Thor
    desc 'pdf PDF', 'processa PDF criando pasta de documentos para arquivo'
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
    def dir(fdir)
      return unless File.ftype(fdir) == 'directory'

      C118dir.new(fdir).processa_pasta(options)
    end
  end
end
