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
    # @return [Float] segundos do mp3
    attr_reader :size

    # @return [String] nome segmento
    attr_reader :nome

    # @return [C118mp3] mp3 c118
    def initialize(fmp3)
      @file = fmp3
      @ext = File.extname(fmp3).downcase
      @base = File.basename(fmp3, File.extname(fmp3))
      @size = `soxi -V0 -D #{fmp3} #{O1}`.to_f
    end

    def processa_mp3(options, npr)
      cmd = if npr
              "noisered #{npr} #{format('%<v>.5f', v: options[:amount])} "
            else
              ''
            end
      cmd += "rate -v #{options[:rate]}k"
      system "sox -G #{file} tmp/zip/#{base}.mp3 #{cmd} #{O2}"
      # puts base
    end

    def segmenta(tps, pse, cmd)
      return cmd[1..-1] unless pse < tps.size

      puts proximo_segmento(pse)

      cmd += ";sox #{file} #{nome} trim #{tps[pse]}"
      pse += 1
      cmd += " =#{tps[pse]}" if pse < tps.size

      segmenta(tps, pse, cmd + " #{O2}")
    end

    def proximo_segmento(pse)
      out = "s#{format('%<v>02d', v: pse)}-#{base[/\d{8}/]}#{base[/-\w+/]}"
      @nome = "#{base}/#{out}#{ext}"
      out
    end

    def processa_minuta(options)
      system segmenta(['0'] + options[:tempos], 0, '')
    end

    def processa_minuta?
      return true if ['.mp3', '.m4a', '.wav'].include?(ext) &&
                     size.positive? &&
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
