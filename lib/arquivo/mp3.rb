# frozen_string_literal: true

module Arquivo
  # analisar/processar mp3
  class C118mp3 < String
    # @return [String] nome do ficheiro
    attr_reader :file
    # @return [String] extensao do ficheiro
    attr_reader :ext
    # @return [String] base do ficheiro
    attr_reader :base
    # @return [String] key do documento ft????/rc????/ex??0??/sc??????
    attr_reader :key
    # @return [Integer] tamanho do mp3
    attr_reader :size

    # @return [String] nome segmento
    attr_reader :nome

    # @return [C118mp3] mp3 c118
    def initialize(fmp3)
      @file = fmp3
      @ext = File.extname(fmp3).downcase
      @base = File.basename(fmp3, File.extname(fmp3))
      @key = @base[/\w+/]
      @size = File.size(fmp3)
    end

    def forca_mp3
      o = "tmp/#{base}.mp3"
      system "ffmpeg -i \"#{file}\" -vn #{o} #{CO}" unless ext == '.mp3'
      File.size?(o) ? C118mp3.new(o) : self
    end

    def processa_minuta(options)
      forca_mp3
      p options
    end

    def processa_minuta?
      return true if !File.exist?(base) && File.exist?(file) &&
                     ['.mp3', '.m4a', '.wav'].include?(ext)

      if File.exist?(base)
        puts "erro: #{base} pasta ja existe"
      else
        puts "erro: #{file} nao consigo processar #{ext} audio"
      end
      false
    end
  end
end
