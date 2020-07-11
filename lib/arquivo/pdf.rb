# frozen_string_literal: true

require 'arquivo/extrato'
require 'i18n'

I18n.config.available_locales = :pt

module Arquivo
  # permite processar documentos PDF
  class C118pdf
    # @!group processamento
    # processa pdf para arquivo
    #
    # @param [Hash] dad dados oficiais para reclassificacao de faturas e recibos
    # @example dad
    #   {"ft1901"=>[["ft1901","legal","assembleia","expediente","-1395"]],
    #    "ft1944"=>[["ft1944","banco","juro","dc3029998410","100"],
    #               ["ft1944","banco","irc","dc3029998410","-28"]]}
    def processa_pdf(dad)
      o = "tmp/#{id}-extract.jpg"
      pdf = jpg?(o) ? C118jpg.new(o, opcoes).apara.pdf : self

      # usar trimed pdf somente se for menor que original
      (pdf.size < size ? pdf : self).final(dad[id]).marca
    end

    # @param [Array] kda lista dados para reclassificacao do documento
    # @return [C118pdf] pdf totalmente processado
    # @example kda-ft1901
    #   [["ft1901","legal","assembleia","expediente","-1395"]]
    def final(kda)
      stamp(kda)
      o = "tmp/zip/#{base}.pdf"

      system "#{ghostscript} -sOutputFile=#{o} \"#{file}\" #{O2}"
      # copia original se processado for maior
      system "cp \"#{file}\" #{o}" if File.size(o) > size

      C118pdf.new(o, opcoes)
    end

    # @param kda (see #final)
    # @return [String] texto completo do selo
    def stamp(kda)
      stamp_base(kda)
      return unless kda

      stamp_digitos(kda)
      stamp_mb(kda)
      d = stamp_descricao(kda)
      return if d.empty?

      @base += '-' + I18n.transliterate(d, locale: :pt)
                         .gsub(/[ [[:punct:]]]/, '-')
    end

    # @param kda (see #final)
    # @return [String] texto base do selo
    def stamp_base(kda)
      @base = id + '-' + stamp_rubrica(kda) + stamp_sha
    end

    # @param kda (see #final)
    # @return [String] adiciona digitos do valor absoluto do documento
    # @example kda-ft1901 (see #final)
    def stamp_digitos(kda)
      n = kda.inject(0) { |s, e| s + e[4].to_i }.abs
      @base += '-' + format('%<valor>06d', valor: n)
    end

    # @param kda (see #final)
    # @return [String] adiciona ids dos movimentos multibanco
    # @example kda-ft1904
    #   [["ft1904-mb00016410","material","mangueira","limpeza","-3998"],
    #    ["ft1904-mb00095312","material","lampadas","sos","-4585"]]
    def stamp_mb(kda)
      d = kda.group_by { |e| e[0][/-(mb\d+)/, 1] }
             .keys.join('-')
      @base += '-' + d unless d.size.zero?
    end

    # @param kda (see #final)
    # @return [String] descricoes dos movimentos contabilidade
    # @example kda-rc1911
    #   [[_,_,"quota 2019-Janeiro","glB albino soares","541"],
    #    [_,_,"quota 2019-Fevereiro","glB albino soares","541"]]
    # @example kda-ft1901 (see #final)
    def stamp_descricao(kda)
      if id[0] == 'f'
        kda.group_by { |e| e[2] }
      else
        kda.group_by { |e| e[2][/\d{4}-(\w{3})/, 1] }
      end.keys.filter { |e| e }.join('-')
    end

    # @param kda (see #final)
    # @return [String] rubrica dos movimentos contabilidade
    # @example kda-ft1901 (see #final)
    # @example kda-rc1911 (see #stamp_descricao)
    def stamp_rubrica(kda)
      if kda
        if id[0] == 'f'
          kda.group_by { |e| e[1] }
        else
          # rubrica recibos = id condomino (ex: h3d)
          kda.group_by { |e| e[3][/\w+/] }
        end.keys.join('-')
      else
        base[/-(\w+)/, 1]
      end
    end

    # @return [String] SHA256 do documento para arquivar
    def stamp_sha
      '-' + `sha256sum #{file}`[/\w+/]
    end

    # @param [String] jpg imagem final (se existir)
    # @return [Boolean] scanned pdf?
    def jpg?(jpg)
      return false if id[0] == 'r'

      o = "tmp/#{id}.txt"
      # se pdf contem texto -> not scanned pdf
      system "pdftotext -q -eol unix -nopgbrk \"#{file}\" #{o}"
      return false if File.size?(o)

      system "pdfimages -q -j \"#{file}\" tmp/#{id}"
      # utilizar somente 1 imagem, comvertida em jpg
      system "convert #{Dir.glob("tmp/#{id}-???.???")[0]} #{jpg} #{O2}"

      # jpg demasiado pequeno -> not scanned pdf
      File.size?(jpg) > LT
    end

    # cria pdf com selo no canto inferior esquerdo
    def marca
      # nome pdf com selo determina a ordem das paginas no arquivo final
      o = "tmp/stamped-#{base[/-(\w+)/, 1]}-#{id}.pdf"
      s = '2 2 moveto /Ubuntu findfont 7 scalefont ' \
           "setfont (#{base}) show"
      system "#{ghostscript} -sOutputFile=tmp/stamp-#{id}.pdf -c \"#{s}\";" \
             "pdftk tmp/zip/#{base}.pdf " \
             "stamp tmp/stamp-#{id}.pdf output #{o} #{O2}"
    end

    # cria PDF do dashboard
    def faz_dashboard
      c = 'gs -sDEVICE=pdfwrite ' \
          '-dNOPAUSE -dBATCH -dQUIET -dPDFSETTINGS=/printer ' \
          '-sPAPERSIZE=a4 -dFIXEDMEDIA -dPDFFitPage -dAutoRotatePages=/All'
      system "#{c} -sOutputFile=#{base}-a4.pdf \"#{file}\" #{O2}"
      puts "#{base}-a4"
    end

    # segmenta PDF pelas suas paginas
    def split
      system "pdftk #{file} burst output #{base}/pg%04d-#{base}.pdf;rm -f #{base}/*.txt"
      puts "#{base}-split"
    end
  end
end
