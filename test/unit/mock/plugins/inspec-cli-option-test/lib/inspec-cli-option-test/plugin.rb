# encoding: UTF-8

require 'inspec-cli-option-test/version'

module InspecPlugins
  module CLiOptionTest
    class Plugin < ::Inspec.plugin(2)
      plugin_name :'inspec-cli-option-test'

      cli_option(:cheery, :commands => [:shell]) do
        require 'inspec-cli-option-test/cli_option_cheery'
        InspecPlugins::CliOptionTest::CliOptionCheery
      end
    end
  end
end
