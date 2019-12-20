# frozen_string_literal: true

module Arquivo
  # analisar/processar pasta
  class C118dir < Enumerator
    def obtem_noiseprof(dir, options)
      return unless /minuta/i.match?(dir) && !options[:noise]

      silencio(1, duracao(item), options[:sound]) while next_item
      items.rewind
      @noiseprof = processa_noiseprof
    end

    def silencio(thr, tse, som)
      o = "tmp/silencio-#{File.basename(item)}"

      system "sox #{item} #{o} " \
             "silence 1 #{format('%<valor>.5f', valor: som)}t #{thr}% #{O2}"

      return if silencio?(o, tse) || thr == 3

      silencio(thr + 1, tse, som)
    end

    def silencio?(fss, tse)
      s = duracao(fss)
      return false unless s.positive? && (tse - s > silence)

      @silence = tse - s
      @noiseprof = fss
    end

    def duracao(seg)
      `soxi -V0 -D #{seg} #{O1}`.to_f
    end

    def processa_noiseprof
      return unless silence&.positive?

      e = File.extname(noiseprof)
      o = "tmp/noiseprof-#{File.basename(noiseprof, e)}"
      # obter noiseprof do silencio encontrado
      system "sox #{noiseprof} #{o}#{e} trim 0 #{silence} #{O2};" \
             "sox #{o}#{e} -n noiseprof #{o} #{O2}"

      # so noiseprof validos sao devolvidos
      @silence = 0.0 unless File.size?(o)
      silence.positive? ? o : nil
    end
  end
end
