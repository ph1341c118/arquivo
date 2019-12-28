# frozen_string_literal: true

require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'arquivo/noise'

module Arquivo
  # O1 = '2>/dev/null'
  # O2 = '1>/dev/null 2>&1'
  O1 = ''
  O2 = ''
  AT = ['.mp3', '.m4a', '.wav', '.sox'].freeze

  # permite processar e arquivar pasta com documentos c118
  class C118dir < Enumerator
    # @!group processamento
    # processa items duma pasta - sub-pastas recursivamente
    def processa_items
      n = 0
      while next_item
        if File.ftype(item) == 'directory'
          C118dir.new(item, opcoes).processa_pasta(item)
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

      cmd = if /minuta/i.match?(base)
              "rm -f #{base}.*"
            else
              "rm -f #{base}.*;pdftk tmp/stamped*.pdf cat output #{base}.pdf"
            end
      system cmd + ";cd tmp/zip;tar cf ../../#{base}.tar *" \
                   ";cd ../..;gzip --best #{base}.tar" \
                   '' # ';rm -rf tmp'

      puts "#{base} (#{num})"
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
    #
    # @param pasta (see CLI#dir)
    def processa_pasta(pasta)
      unless File.ftype(items.peek) == 'directory'
        system 'mkdir -p tmp/zip'
        obtem_dados(pasta)
        obtem_noiseprof(pasta)
      end
      processa_items
    end

    # @return [String] proximo item dentro da pasta
    def next_item
      @item = items.next
    rescue StopIteration
      @item = nil
    end

    # @!group dados online
    # @param pasta (see CLI#dir)
    # @return [Hash] dados oficiais para reclassificacao de faturas e recibos
    def obtem_dados(pasta)
      @dados = {}
      # somente faturas e recibos necessitam reclassificacao
      return unless /fac?tura/i.match?(pasta) || /recibo/i.match?(pasta)

      # sheet c118-contas
      dg = '1PbiMrtTtqGztZMhe3AiJbDS6NQE9o3hXebnQEFdt954'
      # range dos dados (faturas/recibos)
      sh = (/fac?tura/i.match?(pasta) ? 'rft' : 'rrc') + '!A2:E'
      @dados = c118_sheets.get_spreadsheet_values(dg, sh).values
                          .group_by { |k| k[0][/\w+/] }
    rescue StandardError
      @dados = {}
    end

    # assegura credenciais validas, obtidas dum ficheiro de credencias
    #
    # @return [Google::Apis::SheetsV4::SheetsService] c118 sheets_v4
    def c118_sheets
      p = '/home/c118/c118-'
      # file obtido console.cloud.google.com/apis OAuth 2.0 client IDs
      i = Google::Auth::ClientId.from_file("#{p}credentials.json")
      s = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
      # file criado aquando new_credentials is executed
      f = Google::Auth::Stores::FileTokenStore.new(file: "#{p}token.yaml")
      z = Google::Auth::UserAuthorizer.new(i, s, f)

      sheets = Google::Apis::SheetsV4::SheetsService.new
      sheets.client_options.application_name = 'c118-arquivo'
      sheets.authorization = z.get_credentials('default') ||
                             new_credentials(z, 'urn:ietf:wg:oauth:2.0:oob')
      sheets
    end

    # inicializar OAuth2 authorization abrindo URL e copiando novo codigo
    #
    # @return [Google::Auth::UserAuthorizer] OAuth2 credentials
    def new_credentials(aut, oob)
      puts 'Open URL and copy code after authorization, in <codigo-aqui>',
           aut.get_authorization_url(base_url: oob)
      aut.get_and_store_credentials_from_code(user_id: 'default',
                                              code: '<codigo-aqui>',
                                              base_url: oob)
    end
  end
end
