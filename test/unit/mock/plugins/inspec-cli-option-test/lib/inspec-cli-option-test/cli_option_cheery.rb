# encoding: utf-8

module InspecPlugins::CliOptionTest
  class CliOptionCheery < Inspec.plugin(2, :cli_option)

    option :cheery, desc: 'Outputs a cheerful message'
  end
end
