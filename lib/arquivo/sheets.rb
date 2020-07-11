# frozen_string_literal: true

require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module Arquivo
  # acede a folhas-calculo c118
  class C118sheets
    # @return (see #sheets_credentials)
    attr_reader :folhas

    # @return [C118sheets] acesso folhas-calculo c118
    def initialize
      sheets_credentials
    end

    # inicializar API sheets com ID cliente & credenciais
    #
    # @return [Google::Apis::SheetsV4::SheetsService] API folhas-calculo c118
    def sheets_credentials
      l = '/home/c118/.sheets.'
      # file obtido console.cloud.google.com/apis OAuth 2.0 client IDs
      i = Google::Auth::ClientId.from_file(l + 'json')
      s = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
      # file criado aquando new_credentials is executed
      f = Google::Auth::Stores::FileTokenStore.new(file: l + 'yaml')
      z = Google::Auth::UserAuthorizer.new(i, s, f)
      @folhas = Google::Apis::SheetsV4::SheetsService.new
      @folhas.client_options.application_name = 'c118-arquivo'
      @folhas.authorization = z.get_credentials('default') || new_credentials(z, 'urn:ietf:wg:oauth:2.0:oob')
    end

    # inicializar OAuth2 authorization abrindo URL e copiando novo codigo
    #
    # @return [Google::Auth::UserAuthorizer] OAuth2 credentials
    def new_credentials(aut, oob)
      puts 'Open URL and copy code after authorization, in <codigo-aqui>', aut.get_authorization_url(base_url: oob)
      aut.get_and_store_credentials_from_code(user_id: 'default', code: '<codigo-aqui>', base_url: oob)
    end
  end
end
