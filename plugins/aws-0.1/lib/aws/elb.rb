require 'thor'

module Skyed
  module Aws
    module Elb
      # ELB CLI for Skyed
      class Elb < Thor
        desc 'check', 'Checks instance status in one ELB'
        def check
          fail NotImplementedError, 'aws elb check is not implemented yet'
        end
      end
    end

    # Local CLI for Aws (Monkeypatching)
    class Aws < Thor
      desc 'elb', 'Manage ELBs'
      subcommand 'elb', Skyed::Aws::Elb::Elb
    end
  end
end
