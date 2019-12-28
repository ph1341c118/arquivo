# frozen_string_literal: true

module Arquivo
  # permite processar e arquivar pasta com documentos c118
  class C118dir < Enumerator
    # @return [Enumerator] items dentro duma pasta
    attr_reader :items
    # @return [String] base nome ficheiros para arquivo (pdf, tar.gz)
    attr_reader :base
    # @return [Hash] parametrizar JPG, MINUTA
    attr_reader :opcoes
    # @return [String] documento c118
    attr_reader :item

    # @return (see #obtem_dados)
    attr_reader :dados
    # @return (see #obtem_noiseprof)
    attr_reader :noiseprof

    # @param pasta (see CLI#dir)
    # @param [Hash] opt parametrizar JPG, MINUTA
    # @option opt [Numeric] :fuzz (29) trim jpg N-1, escolhe menor ->
    #   scanned pdf
    # @option opt [Numeric] :quality (15) compress jpg N% -> scanned pdf
    #   (less=low quality)
    # @option opt [Numeric] :threshold (9) limiar maximo para silencio,
    #   0% = silencio puro
    # @option opt [Numeric] :sound (1) segundos de som para terminar silencio
    # @option opt [Numeric] :amount (0.00001) qtd ruido a ser removido,
    # @option opt [Numeric] :rate (16) sample rate - radio-16k, CD-44.1k,
    #   PC-48k, pro-96k
    # @return [C118dir] pasta de documentos c118
    def initialize(pasta, opt)
      @items = Dir.glob(File.join(pasta, '*')).each
      @base = File.basename(pasta, File.extname(pasta)) + '-' +
              Date.today.strftime('%Y%m%d')
      @opcoes = opt
    end

    # @!group perfil silencio
    # @param pasta (see CLI#dir)
    # @return [String] perfil do maior silencio inicial de todos segmentos audio
    def obtem_noiseprof(pasta)
      return unless /minuta/i.match?(pasta)

      l = obtem_segmentos(pasta)
      return unless l.size.positive?

      t = -1
      m = ['', 0]
      m = obtem_maximo_silencio(l, t += 1) while noisy?(m, t)

      cria_noiseprof(m)
    end

    # @param [Array<String, Float>] seg segmento, duracao silencio inicial
    # @param thr (see #obtem_maximo_silencio)
    # @return [Boolean] segmento audio tem som ou silencio no inicio
    def noisy?(seg, thr)
      thr < opcoes[:threshold] && seg[1] <= opcoes[:sound]
    end

    # @param [Array] lsg lista segmentos audio com duracoes
    # @param [Numeric] thr limiar para silencio em processamento
    # @return [Array<String, Float>] segmento com maior duracao silencio inicial
    def obtem_maximo_silencio(lsg, thr)
      lsg.sort.map { |e| obtem_silencio(e, thr) }.max_by { |_, s| s }
    end

    # @param [Array<String, Float>] seg segmento audio, duracao
    # @param thr (see #obtem_maximo_silencio)
    # @return [Array<String, Float>] segmento audio, duracao silencio inicial
    def obtem_silencio(seg, thr)
      o = "tmp/thr-#{File.basename(seg[0])}"
      system "sox #{seg[0]} #{o} silence 1 #{opcoes[:sound]}t #{thr}% #{O2}"

      [seg[0], (seg[1] - duracao(o)).round(2, half: :down)]
    end

    # @param seg (see #noisy?)
    # @return [String] perfil sonoro do silencio inicial dum segmento
    def cria_noiseprof(seg)
      return unless seg[1] > opcoes[:sound]

      o = "tmp/noiseprof-#{File.basename(seg[0], File.extname(seg[0]))}"
      # obter noiseprof do silencio no inicio
      system "sox #{seg[0]} -n trim 0 #{seg[1]} noiseprof #{o} #{O2}"

      # so noiseprof validos sao devolvidos
      @noiseprof = File.size?(o).positive? ? o : nil
    end

    # @param pasta (see CLI#dir)
    # @return [Array] lista segmentos audio com duracoes
    def obtem_segmentos(pasta)
      AT.map { |e| Dir.glob(File.join(pasta, 's[0-9][0-9]-*' + e)) }.flatten
        .map { |s| [s, duracao(s)] }
    end

    # @param [String] audio ficheiro de audio
    # @return [Float] duracao ficheiro audio em segundos
    def duracao(audio)
      `soxi -V0 -D #{audio} #{O1}`.to_f
    end
  end
end
