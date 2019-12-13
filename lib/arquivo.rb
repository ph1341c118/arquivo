# frozen_string_literal: true

require 'thor'
# require 'arquivo/version'
# require 'arquivo/extrato'
# require 'arquivo/pdf'
# require 'arquivo/dir'
# require 'arquivo/jpg'
require '/home/c118/ruby/arquivo/lib/arquivo/version.rb'
require '/home/c118/ruby/arquivo/lib/arquivo/extrato.rb'
require '/home/c118/ruby/arquivo/lib/arquivo/pdf.rb'
require '/home/c118/ruby/arquivo/lib/arquivo/dir.rb'
require '/home/c118/ruby/arquivo/lib/arquivo/jpg.rb'

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
                  desc: 'fuzziness para corte das imagens no pdf'
    option :quality, type: :numeric, default: 15,
                     desc: 'qualidade das imagens no pdf'
    def dir(fdir)
      return unless File.ftype(fdir) == 'directory'

      system 'mkdir -p tmp/zip'
      C118dir.new(fdir).processa_pasta(options)
      # system 'rm -rf tmp'
    end
  end
end
