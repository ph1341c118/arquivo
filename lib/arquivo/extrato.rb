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

    # @return [String] texto duma pagina pdf
    attr_reader :page
    # @return [String] base extrato processado
    attr_reader :nome
    # @return [String] list paginas extrato processado
    attr_reader :list

    # @return [String] key do documento ft????/rc????/ex??0??/sc??????
    attr_reader :key
    # @return [Numeric] tamanho do pdf
    attr_reader :size

    # @return [C118jpg] scanned jpg em processamento
    attr_reader :pjpg
    # @return [C118pdf] pdf em processamento
    attr_reader :ppdf

    # @return [C118pdf] pdf c118
    def initialize(fpdf)
      @file = fpdf
      @ext = File.extname(fpdf).downcase
      @base = File.basename(fpdf, File.extname(fpdf)).downcase

      @key = @base[/\w+/]
      @size = File.size(fpdf)

      @ppdf = self
    end

    def c118_gs
      # filtrar images para scq e extratos
      fi = /^[se]/i.match?(key.to_s) ? ' -dFILTERIMAGE' : ''

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
                     first_page

      if File.exist?(base)
        puts "erro: #{base} pasta ja existe"
      else
        puts "erro: #{file} nao consigo obter primeira pagina do PDF"
      end
      false
    end

    def processa_extrato(cnt)
      cnt += 1
      @list += ',' + cnt.to_s if c118_conta?
      if next_page
        faz_extrato if extrato?
        processa_extrato(cnt)
      else
        faz_extrato
      end
    end

    def extrato?
      c118_conta? && page.match?(/extrato +combinado/i)
    end

    def faz_extrato
      system "#{c118_gs} " \
        "-sOutputFile=#{base}/#{nome}-extrato.pdf " \
        "-sPageList=#{list[1..-1]} \"#{file}\" 1>/dev/null 2>&1"
      puts "#{nome}-extrato"
      base_extrato
    end

    def c118_conta?
      page.include?('45463760224')
    end

    # @return [PDF::Reader] leitor pdf
    def rpdf
      @rpdf ||= PDF::Reader.new(file).pages.lazy
    rescue StandardError
      @rpdf = nil
    end

    # @return [String] texto duma pagina pdf
    def next_page
      @page = rpdf.next.text
    rescue StopIteration
      @page = nil
    end

    def base_extrato
      return false unless page

      @list = ''
      n = page.scan(%r{N\. *(\d+)/(\d+)}).flatten
      @nome = "ex#{n[0].to_s[/\d{2}$/]}#{n[1]}"
    rescue StandardError
      @nome = nil
    end

    def first_page
      rpdf && next_page && base_extrato
    end

    def split
      system "pdftk #{file} burst output #{base}/pg%04d-#{base}.pdf;" \
             "rm -f #{base}/*.txt"
    end
  end
end
