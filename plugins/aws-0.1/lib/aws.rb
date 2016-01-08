require 'thor'

module Skyed
  # AWS CLI for Skyed
  class Aws < Thor
    class_option :credentials,
                 aliases: '-c',
                 desc: 'AWS credentials file',
                 default: '$HOME/.aws/credentials'

    desc 'list', 'List AWS accounts'
    def list
      fail NotImplementedError
    end
  end

  # Main CLI for Skyed (Monkeypatching)
  class CLI < Thor
    desc 'aws', 'Manage AWS settings'
    subcommand 'aws', Skyed::Aws
  end
end
