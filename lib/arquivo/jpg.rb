# frozen_string_literal: true

require 'fastimage'

module Arquivo
  # analisar/processar pdf
  class C118jpg < String
    # @return [String] nome do ficheiro
    attr_reader :file
    # @return [String] extensao do ficheiro
    attr_reader :ext
    # @return [String] base do ficheiro
    attr_reader :base

    # @return [String] key do documento ft????/rc????/ex??0??/sc??????
    attr_reader :key
    # @return [Numeric] tamanho do jpg
    attr_reader :size

    # @return [C118jpg] jpg c118
    def initialize(fjpg)
      @file = fjpg
      @ext = File.extname(fjpg).downcase
      @base = File.basename(fjpg, File.extname(fjpg)).downcase

      @key = @base[/\w+/]
      @size = File.size(fjpg)
    end

    def processa_jpg(options, dados)
      trim(options).jpg2pdf(options).final(dados[key])
    end

    def trim(options)
      f = options[:fuzz]
      h = {}
      # obter jpg menor triming borders ao maximo
      while f >= 1
        system "convert \"#{file}\" -fuzz #{f}% -trim +repage " \
               "tmp/#{base}#{f}.jpg "
        h[f] = File.size("tmp/#{base}#{f}.jpg")
        f -= 4
      end
      m = h.min_by { |_, v| v }
      m[1].between?(LT, size) ? C118jpg.new("tmp/#{base}#{m[0]}.jpg") : self
    end

    def jpg2pdf(options)
      o = "tmp/#{base}.pdf"

      # Center image on a larger canvas (with a size given by "-extent").
      x, y = scale_xy
      system "convert \"#{file}\" -units PixelsPerInch " \
             "-gravity center -extent #{x}x#{y} " \
             "-quality #{options[:quality]}% -compress jpeg -format pdf " \
             "#{o} 1>/dev/null 2>&1"

      # devolve pdf processado a partir de jpg
      C118pdf.new(o)
    end

    def scale_xy
      # Determine image dimensions in pixels.
      x, y = FastImage.size(file)

      # Calculate image density (in dpi) needed to fit the image
      # with a 5% border all around an A4 page.
      # Factor 1.1 creates 2*5% borders,
      # Use the higher density to prevent exceeding the required fit.
      density = [x / X4 * 1.04, y / Y4 * 1.04].max

      # Calculate canvas dimensions in pixels.
      # (Canvas is an A4 page with the calculated density.)
      [X4 * density, Y4 * density]
    end
  end
end
