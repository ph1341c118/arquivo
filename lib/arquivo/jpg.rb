# frozen_string_literal: true

require 'fastimage'

module Arquivo
  # tipos de audio que consigo processa
  LT = 9000

  # A4 page (8.27x11.69) inches
  X4 = 8.27
  Y4 = 11.69

  # to calculate image density (in dpi) needed to fit
  # the image with a 2% border all around an A4 page.
  # Factor 1.04 creates 2*2% borders,
  FB = 1.04

  # permite processar documentos em imagens JPG
  class C118jpg < String
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

    # @param [String] jpg JPG c118
    # @param [Hash] opt parametrizar JPG
    # @option opt [Numeric] :fuzz (29) trim jpg N-1, escolhe menor ->
    #   scanned pdf
    # @option opt [Numeric] :quality (15) compress jpg N% -> scanned pdf
    #   (less=low quality)
    # @return [C118jpg] JPG c118
    def initialize(jpg, opt)
      @file = jpg
      @ext = File.extname(jpg).downcase
      @base = File.basename(jpg, File.extname(jpg))
      @id = @base[/\w+/]
      @size = File.size(jpg)
      @opcoes = opt
    end

    # @!group processamento
    # apara jpg e converte em pdf para arquivo
    #
    # @param dad (see C118pdf#processa_pdf)
    def processa_jpg(dad)
      apara.pdf.final(dad[id]).marca
    end

    # @return [C118jpg] jpg com melhor aparo
    def apara
      system cmd_apara(opcoes[:fuzz], '')
      melhor_aparo
    end

    # @return (see #apara)
    def melhor_aparo
      m = Dir.glob("tmp/#{id}-*.jpg")
             .map { |s| [s, File.size(s)] }
             .min_by { |_, v| v.between?(LT, size) ? v : size }
      m[1] < size ? C118jpg.new(m[0], opcoes) : self
    end

    # @return [String] comando para aparar imagem
    def cmd_apara(fuzz, cmd)
      return cmd[1..-1] unless fuzz >= 1

      cmd += ";convert \"#{file}\" -fuzz #{fuzz}% -trim +repage " \
             "#{oqualidade} tmp/#{id}-#{fuzz}.jpg #{O2}"

      cmd_apara(fuzz - 4, cmd)
    end

    # @return [C118pdf] pdf com jpg processada dentro
    def pdf
      system "convert \"#{file}\" #{oa4} #{oqualidade} " \
             "-format pdf tmp/#{id}-trimed.pdf #{O2}"

      C118pdf.new("tmp/#{id}-trimed.pdf", opcoes)
    end

    # @return [String] opcoes comprimir jpg
    def oqualidade
      "-quality #{opcoes[:quality]}% -compress jpeg"
    end

    # @return [String] opcoes centrar jpg em canvas A4
    def oa4
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
