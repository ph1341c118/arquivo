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
    # @return [String] final do nome do segmento
    attr_reader :final
    # @return [Float] segundos do mp3
    attr_reader :size

    # @return [C118mp3] mp3 c118
    def initialize(fmp3)
      @file = fmp3
      @ext = File.extname(fmp3).downcase
      @base = File.basename(fmp3, File.extname(fmp3))
      @final = "-#{@base[/\d{8}/]}#{@base[/-\w+/]}#{@ext}"
      @size = `soxi -V0 -D #{fmp3} #{O1}`.to_f
    end

    def forca_mp3
      o = "tmp/#{base}.mp3"
      system "sox \"#{file}\" #{o} #{O2}" unless ext == '.mp3'
      File.size?(o) ? C118mp3.new(o) : self
    end

    def processa_mp3
      system processa_segmentos(Dir.glob("tmp/#{base}*#{ext}"),
                                0, '', options[:amount])
    end

    def processa_segmentos(ase, pse, cmd, amt)
      return cmd[1..-1] unless pse < ase.size

      fls = "#{base}/s#{pse}#{final} " \
        "tmp/s#{pse}-#{final}#{base[/-\w+/]}.mp3"
      cmd += nprof ? ";sox #{fls} noisered #{nprof} #{ff(amt)}" : ";cp #{fls}"

      processa_segmentos(ase, pse + 1, cmd, amt)
    end

    def ff(val)
      format('%<valor>.5f', valor: val)
    end

    def segmenta(tps, pse, cmd)
      return cmd[1..-1] unless pse < tps.size

      cmd += ";sox #{file} #{base}/s#{pse}#{final} trim #{tps[pse]}"
      pse += 1
      cmd += " =#{tps[pse]}" if pse < tps.size

      segmenta(tps, pse, cmd + " #{O2}")
    end

    def processa_minuta(options)
      system segmenta(['0'] + options[:tempos], 0, '')
    end

    def processa_minuta?
      return true if ['.mp3', '.m4a', '.wav'].include?(ext) &&
                     !File.exist?(base)

      if File.exist?(base)
        puts "erro: #{base} pasta ja existe"
      else
        puts "erro: #{file} nao consigo processar minuta"
      end

      false
    end
  end
end
