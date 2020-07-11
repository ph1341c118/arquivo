# frozen_string_literal: true

require 'pdf-reader'

module Arquivo
  # permite processar documentos PDF
  class C118pdf
    # @return [String] nome do documento
    attr_reader :file
    # @return [String] extensao do documento
    attr_reader :ext
    # @return [String] base do documento
    attr_reader :base
    # @return [Integer] tamanho do documento
    attr_reader :size
    # @return [Hash] opcoes parametrizar JPG
    attr_reader :opcoes
    # @return [String] id do documento ft/rc/ex/sc <numero>
    attr_reader :id

    # @return [Array<Integer>] lista paginas do extrato
    attr_reader :paginas
    # @return [String] texto pagina
    attr_reader :pagina
    # @return [String] nome extrato
    attr_reader :nome

    # @param [String] pdf PDF c118
    # @param opt (see C118jpg#initialize)
    # @option opt (see C118jpg#initialize)
    # @return [C118pdf] PDF c118
    def initialize(pdf, opt)
      @file = pdf
      @ext = File.extname(pdf).downcase
      @base = File.basename(pdf, File.extname(pdf))
      @id = @base[/\w+/]
      @size = File.size(pdf)
      @opcoes = opt
    end

    # @!group segmentacao
    # segmenta extrato limpando publicidade
    #
    # @param [Integer] cnt contador pagina em processamento
    def processa_extrato(cnt)
      cnt += 1
      @paginas << cnt if pagina_extrato?
      if proxima_pagina
        faz_extrato if novo_extrato?
        processa_extrato(cnt)
      else
        faz_extrato
      end
    end

    # @return [Boolean] posso segmentar extrato?
    def processa_extrato?
      return true if ext == '.pdf' && size.positive? && !File.exist?(base) &&
                     first_pagina?

      if File.exist?(base)
        puts "erro: #{base} pasta ja existe"
      else
        puts "erro: #{file} nao consigo obter primeira pagina do EXTRATO"
      end
      false
    end

    # @return [Boolean] primeira pagina de extrato?
    def novo_extrato?
      pagina_extrato? && pagina.match?(/extrato +combinado/i)
    end

    # @return [Boolean] pagina de extrato?
    def pagina_extrato?
      pagina.include?('45463760224')
    end

    # @return [Boolean] primeira pagina?
    def first_pagina?
      leitor && proxima_pagina && nome_extrato
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

    # @return [String] nome proximo extrato
    def nome_extrato
      return false unless pagina

      @paginas = []
      n = pagina.scan(%r{N\. *(\d+)/(\d+)}).flatten
      @nome = n.empty? ? nil : "ex#{n[1]}-#{n[0]}"
    rescue StandardError
      @nome = nil
    end

    # @return [String] comando PDF language interpreter c118
    def ghostscript
      # filtrar images para scq e extratos
      fi = /^[se]/i.match?(id) ? ' -dFILTERIMAGE' : ''

      'gs -sDEVICE=pdfwrite ' \
        '-dNOPAUSE -dBATCH -dQUIET ' \
        '-sPAPERSIZE=a4 -dFIXEDMEDIA -dPDFFitPage ' \
        '-dPDFSETTINGS=/screen -dDetectDuplicateImages ' \
        '-dColorImageDownsampleThreshold=1 ' \
        '-dGrayImageDownsampleThreshold=1 ' \
        '-dMonoImageDownsampleThreshold=1' + fi
    end

    # cria PDF do extrato
    def faz_extrato
      system "#{ghostscript} " \
        "-sOutputFile=#{base}/#{nome}-extrato.pdf " \
        "-sPageList=#{paginas.join(',')} \"#{file}\" #{O2}"
      puts "#{nome}-extrato"
      nome_extrato
    end
  end
end
