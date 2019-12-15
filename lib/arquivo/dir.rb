# frozen_string_literal: true

require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module Arquivo
  # CO = '1>/dev/null 2>&1'
  CO = ''

  # analisar/processar pasta
  class C118dir < Enumerator
    # @return [Enumerator] lista items dentro duma pasta
    attr_reader :items
    # @return [String] documento c118
    attr_reader :item
    # @return [Hash] dados (faturas/recibos) de c118-contas
    attr_reader :dados

    # @return [String] base nome ficheiros finais (pdf, tar.gz)
    attr_reader :base

    # @return [C118dir] documentos c118
    def initialize(pasta)
      @items = Dir.glob(File.join(pasta, '*')).each
      @base = File.basename(pasta, File.extname(pasta)) +
              Date.today.strftime('%Y%m%d')
      obtem_dados(pasta)
      system 'mkdir -p tmp/zip'
    end

    # @return [String] ficheiro dentro da pasta
    def next_item
      @item = items.next
    rescue StopIteration
      @item = nil
    end

    def processa_pasta(options)
      n = 0
      while next_item
        if File.ftype(item) == 'directory'
          C118dir.new(item).processa_pasta(options)
        else
          processa_file(options, File.extname(item).downcase)
          n += 1
        end
      end
      processa_fim(n) if n.positive?
    end

    def processa_fim(num)
      system "rm -f #{base}.*;" \
             "pdftk tmp/stamped*.pdf cat output #{base}.pdf;" \
             "cd tmp/zip;tar cf ../../#{base}.tar *.pdf;" \
             "cd ../..;gzip --best #{base}.tar;" \
             'rm -rf ./tmp'
      puts "#{base} (#{num})"
    end

    def processa_file(options, ext)
      case ext
      when '.mp3' then puts item
      when '.jpg' then C118jpg.new(item).processa_jpg(options, dados)
      when '.pdf' then C118pdf.new(item).processa_pdf(options, dados)
      else
        puts "erro: #{item} so posso processar mp3, jpg, pdf"
      end
    end

    def obtem_dados(dir)
      return unless /fac?tura/i.match?(dir) ||
                    /recibo/i.match?(dir) ||
                    dados.empty?

      # obtem dados (faturas/recibos) da sheet c118-contas
      id = '1PbiMrtTtqGztZMhe3AiJbDS6NQE9o3hXebnQEFdt954'
      sh = (/fac?tura/i.match?(dir) ? 'rft' : 'rrc') + '!A2:E'
      @dados = c118_sheets.get_spreadsheet_values(id, sh).values
                          .group_by { |k| k[0][/\w+/] }
    rescue StandardError
      @dados = {}
    end

    # assegura credenciais validas, obtidas dum arquivo de credencias
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
