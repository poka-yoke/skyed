require 'thor'

module Skyed
  module Aws
    module Ow
      # OpsWorks CLI for Skyed
      class Ow < Thor
        desc 'list', 'Lists OpsWorks objects'
        def list
          fail NotImplementedError, 'aws ow list is not implemented yet'
        end

        desc 'create', 'Create new OpsWorks objects'
        def create
          fail NotImplementedError, 'aws ow create is not implemented yet'
        end

        desc 'destroy', 'Destroy existing OpsWorks objects'
        def destroy
          fail NotImplementedError, 'aws ow destroy is not implemented yet'
        end

        desc 'execute', 'Runs command on OpsWorks objects'
        def execute
          fail NotImplementedError, 'aws ow execute is not implemented yet'
        end

        desc 'stop', 'Stops OpsWorks objects'
        def stop
          fail NotImplementedError, 'aws ow stop is not implemented yet'
        end
      end
    end

    # Local CLI for Aws (Monkeypatching)
    class Aws < Thor
      desc 'ow', 'Manage OpsWorks'
      subcommand 'ow', Skyed::Aws::Ow::Ow
    end
  end
end
