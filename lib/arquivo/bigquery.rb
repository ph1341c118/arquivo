# frozen_string_literal: true

require 'google/cloud/bigquery'

module Arquivo
  # permite arquivar dados c118 no bigquery
  class C118bigquery < C118sheets
    # @return [Google::Cloud::Bigquery] API bigquery c118
    attr_reader :big

    # @return [C118bigquery] acesso bigquery c118
    def initialize
      # inicializar API sheets com ID cliente & credenciais
      sheets_credentials

      # This uses Application Default Credentials to authenticate.
      # @see https://cloud.google.com/bigquery/docs/authentication/getting-started
      @big = Google::Cloud::Bigquery.new
    end

    # obtem dados da folha c118 & processa no bigquery
    def processa_big
      # folha c118-contas
      s = '1PbiMrtTtqGztZMhe3AiJbDS6NQE9o3hXebnQEFdt954'
      a = folhas.get_spreadsheet_values(s, 'cbd!AJ2').values.flatten[0]
      i = folhas.get_spreadsheet_values(s, 'bal!R2:R').values.flatten.join(',')
      puts 'processamento bigquery feito para ano ' + a + ": [del_bal,del_hise,ins_bal,ins_hise] #{sql_big(a, i)}"
    end

    # executa comandos DML para processa no bigquery
    #
    # @return [Array<Integer>] numero linhas afetadas pelos DMLs
    def sql_big(ano, lst)
      [dml('delete FROM arquivo.bal  WHERE ano=' + ano),
       dml('delete FROM arquivo.hise WHERE ano=' + ano),
       dml("INSERT arquivo.bal (#{col_bal}) VALUES" + lst),
       dml("INSERT arquivo.hise(#{col_hise}) select * from arquivo.vhe where ano=" + ano)]
    end

    # @return [String] colunas da tabela bal no bigquery
    def col_bal
      'data,entidade,documento,descricao,valor,tag,dr,banco,conta,ano,id4,dref,daa,paga,desb'
    end

    # @return [String] colunas da tabela hise no bigquery
    def col_hise
      'ano,dr,tag,descricao,valor'
    end

    # executa comando DML (Data Manipulation Language) no bigquery
    #
    # @return [Integer] numero linhas afetadas pelo DML
    def dml(sql)
      job = big.query_job(sql)
      job.wait_until_done!
      puts job.error if job.failed?
      job.num_dml_affected_rows
    end
  end
end
