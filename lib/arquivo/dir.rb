# frozen_string_literal: true

require 'arquivo/noise'

module Arquivo
  # permite processar e arquivar pasta com documentos c118
  class C118dir < Enumerator
    # @!group processamento
    # processa items duma pasta
    def processa_items
      n = 0
      while next_item
        if File.ftype(item) == 'directory'
          C118dir.new(item, opcoes).processa_pasta
        else
          processa_file(File.extname(item).downcase)
          n += 1
        end
      end
      processa_fim(n)
    end

    # cria ficheiros finais para arquivo
    #
    # @param [Numeric] num numero de documentos dentro do arquivo
    def processa_fim(num)
      return unless num.positive?

      cmd = if contem == :fsg
              "rm -f #{nome}.*;sox tmp/zip/* #{nome}.mp3"
            else
              "rm -f #{nome}.*;pdftk tmp/stamped* cat output #{nome}.pdf"
            end
      system cmd + ";cd tmp/zip;tar cf ../../#{nome}.tar *" \
                   ";cd ../..;gzip --best #{nome}.tar" \
                   ';rm -rf tmp'

      puts "#{nome} (#{num})"
    end

    # processa ficheiro JPG, PDF ou AUDIO
    #
    # @param [String] ext tipo ficheiro
    def processa_file(ext)
      opt = opcoes
      case ext
      when '.jpg' then C118jpg.new(item, opt).processa_jpg(dados)
      when '.pdf' then C118pdf.new(item, opt).processa_pdf(dados)
      when *AT    then C118mp3.new(item, opt).processa_mp3(noiseprof)
      else
        puts "erro: #{ext} nao posso processar este tipo de dicheiro"
      end
    end

    # processa conteudo duma pasta
    def processa_pasta
      if contem
        system 'mkdir -p tmp/zip'
        obtem_dados
        obtem_noiseprof
      end
      processa_items
    end

    # @return [String] proximo item dentro da pasta
    def next_item
      @item = items.next
    rescue StopIteration
      @item = nil
    end

    # @!group dados folhas-calculo c118
    # @return [Hash] dados oficiais para classificacao de faturas e recibos
    def obtem_dados
      @dados = {}
      # somente faturas e recibos necessitam reclassificacao
      return unless %i[fft frc].include?(contem)

      # folha c118-contas
      s = '1PbiMrtTtqGztZMhe3AiJbDS6NQE9o3hXebnQEFdt954'
      @dados = C118sheets.new.folhas
                         .get_spreadsheet_values(s, contem.to_s + '!A2:E')
                         .values.group_by { |k| k[0][/\w+/] }
    rescue StandardError
      @dados = {}
    end
  end
end
