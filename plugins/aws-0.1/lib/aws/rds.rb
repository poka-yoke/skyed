require 'thor'

module Skyed
  module Aws
    module Rds
      # RDS CLI for Skyed
      class Rds < Thor
        desc 'list', 'Lists Db Instances'
        def list
          fail NotImplementedError, 'aws rds list is not implemented yet'
        end

        desc 'create', 'Create new Db Instances'
        def create
          fail NotImplementedError, 'aws rds create is not implemented yet'
        end

        desc 'destroy', 'Destroy existing Db Instances'
        def destroy
          fail NotImplementedError, 'aws rds destroy is not implemented yet'
        end
      end
    end

    # Local CLI for Aws (Monkeypatching)
    class Aws < Thor
      desc 'rds', 'Manage RDSs'
      subcommand 'rds', Skyed::Aws::Rds::Rds
    end
  end
end
