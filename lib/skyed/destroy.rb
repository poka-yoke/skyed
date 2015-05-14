module Skyed
  # This module encapsulates all the destroy command steps.
  module Destroy
    class << self
      def execute(_global_options, _options, _args)
        repo_path = Skyed::Settings.repo
        hostname = `cd #{repo_path} && vagrant ssh -c hostname`.strip
        `cd #{repo_path} && vagrant destroy -f`
        ow = Skyed::AWS::OpsWorks.login
        instance = Skyed::AWS::OpsWorks.instance_by_name(
          hostname, Skyed::Settings.stack_id, ow)
        ow.deregister_instance(instance_id: instance[:instance_id])
        wait_for_instance(hostname, Skyed::Settings.stack_id, ow)
      end

      def wait_for_instance(hostname, stack_id, opsworks)
        instance = Skyed::AWS::OpsWorks.instance_by_name(
          hostname, stack_id, opsworks)
        while instance[:status] != 'terminated'
          sleep(0)
          instance = Skyed::AWS::OpsWorks.instance_by_name(
            hostname, stack_id, opsworks)
        end
      end
    end
  end
end
