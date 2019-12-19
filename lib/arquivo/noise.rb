# frozen_string_literal: true

module Arquivo
  # analisar/processar pasta
  class C118dir < Enumerator
    def silencio(thr, tse, som)
      out = "tmp/silencio-#{File.basename(item)}"

      system "sox #{item} #{out} " \
             "silence 1 #{format('%<valor>.5f', valor: som)}t #{thr}% #{O2}"

      return if silencio?(out, tse) || thr == 3

      silencio(thr + 1, pse, tse, som)
    end

    def silencio?(fss, tse)
      s = duracao(fss)
      return false unless s.positive? && (tse - s > silence)

      @silence = tse - s
      @nprof = fss
    end

    def duracao(seg)
      `soxi -V0 -D #{seg} #{O1}`.to_f
    end

    def noiseprof
      return unless silence&.positive?

      o = "tmp/prof-#{base}"
      # obter noiseprof do silencio encontrado
      system "sox #{nprof} #{o}#{ext} trim 0 #{silence} #{O2};" \
             "sox #{o}#{ext} -n noiseprof #{o} #{O2}"

      # so noiseprof validos sao devolvidos
      @silence = 0.0 unless File.size?(o)
      silence.positive? ? o : nil
    end
  end
end
