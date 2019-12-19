# frozen_string_literal: true

require 'fastimage'

module Arquivo
  # size limit after trim attempt
  LT = 9000

  # A4 page (8.27x11.69) inches
  X4 = 8.27
  Y4 = 11.69

  # to calculate image density (in dpi) needed to fit
  # the image with a 2% border all around an A4 page.
  # Factor 1.04 creates 2*2% borders,
  FB = 1.04

  # analisar/processar jpg
  class C118jpg < String
    # @return [String] nome do ficheiro
    attr_reader :file
    # @return [String] extensao do ficheiro
    attr_reader :ext
    # @return [String] base do ficheiro
    attr_reader :base
    # @return [String] key do documento ft????/rc????/ex??0??/sc??????
    attr_reader :key
    # @return [Integer] tamanho do jpg
    attr_reader :size

    # @return [C118jpg] jpg c118
    def initialize(fjpg)
      @file = fjpg
      @ext = File.extname(fjpg).downcase
      @base = File.basename(fjpg, File.extname(fjpg))
      @key = @base[/\w+/]
      @size = File.size(fjpg)
    end

    def processa_jpg(options, dados)
      trim(options).converte(options).final(dados[key]).marca
    end

    def parm_trim(options, fuzz)
      "-fuzz #{fuzz}% -trim +repage #{parm_qualidade(options)} " \
        "tmp/#{key}-#{fuzz}.jpg #{O2}"
    end

    def parm_qualidade(options)
      "-quality #{options[:quality]}% -compress jpeg"
    end

    def trim(options)
      f = options[:fuzz]
      h = {}
      # obter jpg menor triming borders ao maximo
      while f >= 1
        system "convert \"#{file}\" #{parm_trim(options, f)}"
        h[f] = File.size("tmp/#{key}-#{f}.jpg")
        f -= 4
      end
      m = h.min_by { |_, v| v }
      m[1].between?(LT, size) ? C118jpg.new("tmp/#{key}-#{m[0]}.jpg") : self
    end

    def converte(options)
      # expande jpg on a larger canvas
      system "convert \"#{file}\" #{expande} #{parm_qualidade(options)} " \
             "-format pdf tmp/#{key}-trimed.pdf #{O2}"

      # devolve pdf processado a partir de jpg
      C118pdf.new("tmp/#{key}-trimed.pdf")
    end

    def expande
      # image dimensions in pixels.
      x, y = FastImage.size(file)

      # use the higher density to prevent exceeding fit
      density = [x / X4 * FB, y / Y4 * FB].max

      # canvas is an A4 page with the calculated density
      '-units PixelsPerInch -gravity center ' \
        "-extent #{X4 * density}x#{Y4 * density}"
    end
  end
end
