# frozen_string_literal: true

module Arquivo
  # permite processar documentos em audio
  class C118mp3 < String
    # @return [String] nome do documento
    attr_reader :file
    # @return [String] extensao do documento
    attr_reader :ext
    # @return [String] base do documento
    attr_reader :base
    # @return [Integer] tamanho do documento
    attr_reader :size
    # @return [Hash] opcoes parametrizar MINUTA
    attr_reader :opcoes

    # @param [String] mp3 MP3 c118
    # @param [Hash] opt parametrizar MINUTA
    # @option opt [Numeric] :amount (0.00001) qtd ruido a ser removido,
    # @option opt [Numeric] :rate (16) sample rate - radio-16k, CD-44.1k,
    #   PC-48k, pro-96k
    # @return [C118mp3] MP3 c118
    def initialize(mp3, opt)
      @file = mp3
      @ext = File.extname(mp3).downcase
      @base = File.basename(mp3, File.extname(mp3))
      @size = `soxi -V0 -D #{mp3} #{O1}`.to_f
      @opcoes = opt
    end

    # @!group processamento
    # Processa mp3 para arquivo
    #
    # @param [String] npr perfil do silencio
    def processa_mp3(npr)
      system "sox -G #{file} tmp/zip/#{base}.mp3 #{onoise(npr)}#{orate} #{O2}"
    end

    # @param npr (see #processa_mp3)
    # @return [String] opcoes reducao ruido de fundo
    def onoise(npr)
      npr ? "noisered #{npr} #{format('%<v>.9f', v: opcoes[:amount])} " : ''
    end

    # @return [String] opcoes sample rate & channels
    def orate
      "rate -v #{opcoes[:rate]}k channels 1"
    end

    # @!group segmentacao
    # Segmenta minuta segundo lista tempos
    #
    # @param [Array] tempos lista tempos para segmentar minuta
    # @example tempos
    #   ["120", "10:11", "[[h:]m:]s", ...]
    def segmenta_minuta(tempos)
      system cmd_segmenta(['0'] + tempos, 0, '')
    end

    # @param [Integer] pse numero do segmento em processamento
    # @return [String] nome do segmento
    def nome_segmento(pse)
      "sg#{format('%<v>02d', v: pse)}-#{base[/\d{8}/]}#{base[/-\w+/]}"
    end

    # @param tempos (see #segmenta_minuta)
    # @param pse (see #nome_segmento)
    # @param [String] cmd comando para segmentar minuta
    # @return [String] comando para segmentar minuta
    def cmd_segmenta(tempos, pse, cmd)
      return cmd[1..-1] unless pse < tempos.size

      o = nome_segmento(pse)
      cmd += ";sox #{file} #{base}/#{o}#{ext} trim #{tempos[pse]}"
      pse += 1
      cmd += " =#{tempos[pse]}" if pse < tempos.size
      puts o

      cmd_segmenta(tempos, pse, cmd + " #{O2}")
    end

    # @return [Boolean] posso segmentar minuta?
    def segmenta_minuta?
      return true if AT.include?(ext) && size.positive? && !File.exist?(base)

      if File.exist?(base)
        puts "erro: #{base} pasta ja existe"
      else
        puts 'erro: so consigo processar minutas com som ' \
             "e do tipo #{AT}"
      end
      false
    end
  end
end
