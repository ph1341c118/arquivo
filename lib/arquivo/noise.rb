# frozen_string_literal: true

module Arquivo
  # analisar/processar pasta
  class C118dir < Enumerator
    def obtem_noiseprof(pasta, options)
      return unless /minuta/i.match?(pasta) && !options[:noise]

      d = Dir.glob(File.join(pasta, '*')).map { |e| [e, duracao(e)] }
      t = 0
      s = ['', 0, 0]
      s = maximo(d, t += 1, options[:sound]) while t < 9 && s[2] <= silence

      processa_silencio(s)
    end

    def processa_silencio(seg)
      return unless seg[2] > silence

      o = "tmp/silencio-#{File.basename(seg[0])}"
      system "sox #{seg[0]} #{o} trim 0 #{seg[2]} #{O2}"
      seg[2] = duracao(o)
      return unless seg[2].positive?

      processa_noiseprof(seg, o)
    end

    def processa_noiseprof(seg, trm)
      o = "tmp/noiseprof-#{File.basename(seg[0], File.extname(seg[0]))}"
      # obter noiseprof do silencio encontrado
      system "sox #{trm} -n noiseprof #{o} #{O2}"

      # so noiseprof validos sao devolvidos
      @silence = File.size?(o) ? seg[2] : 0.0
      @noiseprof = silence.positive? ? o : nil
    end

    def maximo(seg, thr, som)
      seg.sort.map { |e| add_silencio(e, thr, som) }.max_by { |_, _, s| s }
    end

    def add_silencio(seg, thr, som)
      o = "tmp/thr-#{File.basename(seg[0])}"
      system "sox #{seg[0]} #{o} silence 1 #{som}t #{thr}% #{O2}"
      s = (seg[1] - duracao(o)).round(2, half: :down)

      seg + [s > som ? s : 0.0]
    end

    def duracao(seg)
      `soxi -V0 -D #{seg} #{O1}`.to_f
    end
  end
end
