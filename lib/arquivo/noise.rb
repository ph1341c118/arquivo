# frozen_string_literal: true

module Arquivo
  O1 = '2>/dev/null'
  O2 = '1>/dev/null 2>&1'
  # tipos de audio que consigo processar
  AT = %w[.mp3 .m4a .wav .sox].freeze
  # tipos de documentos validos
  # @example contem (see C118dir#obtem_conteudo)
  DT = %i[fsc fsg frc fft fex].freeze

  # permite processar e arquivar pasta com documentos c118
  class C118dir < Enumerator
    # @return [String] local da pasta
    attr_reader :local
    # @return [Enumerator] items dentro duma pasta
    attr_reader :items
    # @return [String] nome ficheiro de arquivo
    attr_reader :nome
    # @return [Hash] parametrizar JPG, MINUTA
    attr_reader :opcoes
    # @return [Symbol] conteudo da pasta
    attr_reader :contem

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
    def initialize(dir, opt)
      c = Dir.glob(File.join(dir, '*'))
      puts c
      @local = dir
      puts @local
      @items = c.each
      @nome = File.basename(dir, File.extname(dir)) + '-' +
              Date.today.strftime('%Y%m%d')
      @opcoes = opt
      @contem = obtem_conteudo(c)
      puts @contem
    end

    # Agrupa conteudo duma pasta segundo tipos de documentos validos
    #
    # @param [Array] fls lista items duma pasta
    # @return [Symbol] tipo de conteudo
    # @example contem
    #   :fsc scq
    #   :fsg minutas
    #   :frc recibos
    #   :fft faturas
    #   :fex extratos
    def obtem_conteudo(fls)
      t = fls.group_by { |f| File.ftype(f)[0] + File.basename(f)[0, 2] }.keys
      return unless t.size == 1 && DT.include?(t[0].to_sym)

      t[0].to_sym
    end

    # @!group perfil silencio
    # @return [String] perfil do maior silencio inicial de todos segmentos audio
    def obtem_noiseprof
      return unless contem == :fsg

      l = obtem_segmentos
      return unless l.size.positive?

      t = -1
      m = ['', 0]
      m = maximo_silencio(l, t += 1) while noisy?(m[1], t)

      cria_noiseprof(m)
    end

    # @param [Float] sin duracao silencio
    # @param thr (see #maximo_silencio)
    # @return [Boolean] segmento audio tem som ou silencio no inicio
    def noisy?(sin, thr)
      thr < opcoes[:threshold] && sin <= opcoes[:sound]
    end

    # @param [Array] lsg lista segmentos audio com duracoes e file silencio
    # @param [Numeric] thr limiar para silencio em processamento
    # @return [Array<String, Float>] segmento com maior duracao silencio inicial
    def maximo_silencio(lsg, thr)
      system lsg.inject('') { |s, e| s + cmd_silencio(e, thr) }[1..-1]
      lsg.map { |e| [e[0], duracao_silencio(e)] }.max_by { |_, s| s }
    end

    # @param [Array<String, Float, String>] seg segmento, duracao, file silencio
    # @param thr (see #maximo_silencio)
    # @return [String] comando para cortar silencio inicial sum segmento
    def cmd_silencio(seg, thr)
      ";sox #{seg[0]} #{seg[2]} silence 1 #{opcoes[:sound]}t #{thr}% #{O2}"
    end

    # @param seg (see #cmd_silencio)
    # @return [Float] duracao silencio em segundos
    def duracao_silencio(seg)
      (seg[1] - duracao(seg[2])).round(2, half: :down)
    end

    # @param [Array<String, Float>] seg segmento, duracao silencio inicial
    # @return [String] perfil sonoro do silencio inicial dum segmento
    def cria_noiseprof(seg)
      return unless seg[1] > opcoes[:sound]

      o = "tmp/noiseprof-#{File.basename(seg[0], File.extname(seg[0]))}"
      # obter noiseprof do silencio no inicio
      system "sox #{seg[0]} -n trim 0 #{seg[1]} noiseprof #{o} #{O2}"

      # so noiseprof validos sao devolvidos
      @noiseprof = File.size?(o).positive? ? o : nil
    end

    # @return [Array] lista segmentos audio com duracoes e file silencio
    def obtem_segmentos
      AT.map { |e| Dir.glob(File.join(local, 'sg*' + e)) }.flatten
        .map { |s| [s, duracao(s), "tmp/thr-#{File.basename(s)}"] }
    end

    # @param [String] audio ficheiro de audio
    # @return [Float] duracao ficheiro audio em segundos
    def duracao(audio)
      `soxi -V0 -D #{audio} #{O1}`.to_f
    end
  end
end
