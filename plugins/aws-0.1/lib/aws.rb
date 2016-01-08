require 'thor'

module Skyed
  module Aws
    # AWS CLI for Skyed
    class Aws < Thor
      class_option :credentials,
                   aliases: '-c',
                   desc: 'AWS credentials file',
                   default: '$HOME/.aws/credentials'

      desc 'list', 'List AWS accounts'
      def list
        fail NotImplementedError, 'aws list is not implemented yet'
      end
    end
  end

  # Main CLI for Skyed (Monkeypatching)
  class CLI < Thor
    desc 'aws', 'Manage AWS settings'
    subcommand 'aws', Skyed::Aws::Aws
  end
end
