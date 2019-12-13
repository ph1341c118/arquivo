# frozen_string_literal: true

require 'i18n'
I18n.config.available_locales = :pt

module Arquivo
  # analisar/processar pdf
  class C118pdf < String
    def processa_pdf(options, dados)
      @ppdf = pjpg.trim(options).jpg2pdf(options) if jpg?
      @ppdf = self if size < ppdf.size
      ppdf.final(dados[key])
    end

    def marca
      # produzir pdf com stamp
      o = "tmp/stamped-#{base[/-(\w+)/, 1]}-#{key}.pdf"
      t = '2 2 moveto /Ubuntu findfont 7 scalefont ' \
           "setfont (#{base}) show"
      system "#{c118_gs} -sOutputFile=tmp/stamp-#{key}.pdf -c \"#{t}\";\
            pdftk tmp/zip/#{base}.pdf stamp tmp/stamp-#{key}.pdf output #{o}"

      C118pdf.new(o)
    end

    def final(kda)
      c118_stamp(kda)
      o = "tmp/zip/#{base}.pdf"

      if key[0] == 'r'
        # google producess better && smaller pdf then c118_gs
        system "cp \"#{file}\" #{o}"
      else
        system "#{c118_gs} -sOutputFile=#{o} \"#{file}\" 1>/dev/null 2>&1"
      end
      @ppdf = C118pdf.new(o) if File.size(o) <= size
      ppdf.marca
    end

    def base_stamp(kda)
      @base = key + '-' + rubrica(kda) + digest
    end

    def vnum_stamp(kda)
      n = kda.inject(0) { |s, e| s + e[4].to_i }.abs
      @base += '-' + format('%<valor>06d', valor: n)
    end

    def numb_stamp(kda)
      d = kda.group_by { |e| e[0][/-(mb\d{8})/, 1] }
             .keys.join('-')
      @base += '-' + d unless d.size.zero?
    end

    def sfim_stamp(kda)
      if key[0] == 'f'
        kda.group_by { |e| e[2] }
      else
        kda.group_by { |e| e[2][/\d{4}-(\w{3})/, 1] }
      end.keys.filter { |e| e }.join('-')
    end

    def c118_stamp(kda)
      base_stamp(kda)
      return unless kda

      vnum_stamp(kda)
      numb_stamp(kda)
      d = sfim_stamp(kda)
      return if d.empty?

      @base += '-' + I18n.transliterate(d, locale: :pt)
                         .gsub(/[ [[:punct:]]]/, '-')
    end

    def rubrica(kda)
      if kda
        # rubrica obtida da sheet arquivo
        # isto permite fazer re-classificacoes de documentos
        if key[0] == 'f'
          kda.group_by { |e| e[1] }
        else
          kda.group_by { |e| e[3][/\w+/] }
        end.keys.join('-')
      else
        base[/-(\w+)/, 1]
      end
    end

    def digest
      '-' + `sha256sum #{file}`[/\w+/]
    end

    def jpg?
      return false if key[0] == 'r'

      o = "tmp/#{base}.txt"
      # teste scanned pdf (se contem texto -> not scanned)
      system "pdftotext -q -eol unix -nopgbrk \"#{file}\" #{o}"
      return false if File.size?(o)

      @pjpg = extract_jpg
    end

    def extract_jpg
      o = "tmp/#{base}3.jpg"

      system "pdfimages -q -j #{file} tmp/#{base}2"
      # nem sempre as imagens sao jpg
      # somente utilizar a primeira
      g = Dir.glob("tmp/#{base}2*.???")
      system "convert #{g[0]} #{o} 1>/dev/null 2>&1"
      return unless File.size(o) > LT

      C118jpg.new(o)
    end
  end
end
