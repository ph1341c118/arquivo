# frozen_string_literal: true

require 'thor'
require 'arquivo/version'
require 'arquivo/extrato'
require 'arquivo/pdf'
require 'arquivo/dir'
require 'arquivo/jpg'

module Arquivo
  class Error < StandardError; end

  # size limit for trim attempt
  LT = 9000

  # A4 page (8.27x11.69) inches
  X4 = 8.27
  Y4 = 11.69

  # CLI para analisar/processar documentos c118
  class CLI < Thor
    desc 'pdf FILE', 'processa extratos ou faturas'
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
                  desc: 'fuzz trim N-1 jpg -> escolhe menor scanned pdf'
    option :quality, type: :numeric, default: 15,
                     desc: 'compress N% jpg -> scanned pdf (less=low quality)'
    def dir(fdir)
      return unless File.ftype(fdir) == 'directory'

      system 'mkdir -p tmp/zip'
      C118dir.new(fdir).processa_pasta(options)
      # system 'rm -rf tmp'
    end
  end
end
