# frozen_string_literal: true

require 'pdf-reader'

module Arquivo
  # analisar/processar pdf
  class C118pdf < String
    # @return [String] nome do documento
    attr_reader :file
    # @return [String] extensao do documento
    attr_reader :ext
    # @return [String] base do documento
    attr_reader :base
    # @return [String] key do documento ft????/rc????/ex??0??/sc??????
    attr_reader :key
    # @return [Integer] tamanho do pdf
    attr_reader :size

    # @return [Array<Integer>] numeros pagina do extrato final
    attr_reader :paginas
    # @return [String] texto pagina pdf
    attr_reader :pagina
    # @return [String] nome extrato
    attr_reader :nome

    # @return [C118pdf] pdf c118
    def initialize(fpdf)
      @file = fpdf
      @ext = File.extname(fpdf).downcase
      @base = File.basename(fpdf, File.extname(fpdf))
      @key = @base[/\w+/]
      @size = File.size(fpdf)
    end

    def c118_gs
      # filtrar images para scq e extratos
      fi = /^[se]/i.match?(key) ? ' -dFILTERIMAGE' : ''

      'gs -sDEVICE=pdfwrite ' \
        '-dNOPAUSE -dBATCH -dQUIET ' \
        '-sPAPERSIZE=a4 -dFIXEDMEDIA -dPDFFitPage ' \
        '-dPDFSETTINGS=/screen -dDetectDuplicateImages ' \
        '-dColorImageDownsampleThreshold=1 ' \
        '-dGrayImageDownsampleThreshold=1 ' \
        '-dMonoImageDownsampleThreshold=1' + fi
    end

    def processa_extrato?
      return true if !File.exist?(base) &&
                     File.exist?(file) && ext == '.pdf' &&
                     first_extrato

      if File.exist?(base)
        puts "erro: #{base} pasta ja existe"
      else
        puts "erro: #{file} nao consigo obter primeira pagina do PDF"
      end
      false
    end

    def processa_extrato(cnt)
      cnt += 1
      @paginas << cnt if conta_c118?
      if proxima_pagina
        faz_extrato if extrato?
        processa_extrato(cnt)
      else
        faz_extrato
      end
    end

    def extrato?
      conta_c118? && pagina.match?(/extrato +combinado/i)
    end

    def faz_extrato
      system "#{c118_gs} " \
        "-sOutputFile=#{base}/#{nome}-extrato.pdf " \
        "-sPageList=#{paginas.join(',')} \"#{file}\" #{CO}"
      puts "#{nome}-extrato"
      proximo_extrato
    end

    def conta_c118?
      pagina.include?('45463760224')
    end

    # @return [Enumerator::Lazy] leitor pdf
    def leitor
      @leitor ||= PDF::Reader.new(file).pages.lazy
    rescue StandardError
      @leitor = nil
    end

    # @return [String] texto duma pagina pdf
    def proxima_pagina
      @pagina = leitor.next.text
    rescue StopIteration
      @pagina = nil
    end

    def proximo_extrato
      return false unless pagina

      @paginas = []
      n = pagina.scan(%r{N\. *(\d+)/(\d+)}).flatten
      @nome = "ex#{n[0].to_s[/\d{2}$/]}#{n[1]}"
    rescue StandardError
      @nome = nil
    end

    def first_extrato
      leitor && proxima_pagina && proximo_extrato
    end

    def split
      system "pdftk #{file} burst output #{base}/pg%04d-#{base}.pdf;" \
             "rm -f #{base}/*.txt"
    end
  end
end
