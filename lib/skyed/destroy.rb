module Skyed
  # This module encapsulates all the destroy command steps.
  module Destroy
    class << self
      def execute(_global_options, _options, _args)
        repo_path = Skyed::Settings.repo
        hostname = `cd #{repo_path} && vagrant ssh -c hostname`.strip
        `cd #{repo_path} && vagrant destroy -f`
        ow = Skyed::AWS::OpsWorks.login
        deregister_instance hostname, ow
        delete_user ow
      end

      def deregister_instance(hostname, ow)
        instance = Skyed::AWS::OpsWorks.instance_by_name(
          hostname, Skyed::Settings.stack_id, ow)
        ow.deregister_instance(
          instance_id: instance.instance_id) unless instance.nil?
        wait_for_instance(
          hostname, Skyed::Settings.stack_id, ow)
      end

      def delete_user(ow)
        stack = ow.describe_stacks(
          stack_ids: [Skyed::Settings.stack_id])[:stacks][0][:name]
        layer = ow.describe_layers(
          layer_ids: [Skyed::Settings.layer_id])[:layers][0][:name]
        Skyed::AWS::IAM.delete_user "OpsWorks-#{stack}-#{layer}"
      end

      def wait_for_instance(hostname, stack_id, opsworks)
        instance = Skyed::AWS::OpsWorks.instance_by_name(
          hostname, stack_id, opsworks)
        until instance.nil? || instance.status == 'terminated'
          sleep(0)
          instance = Skyed::AWS::OpsWorks.instance_by_name(
            hostname, stack_id, opsworks)
        end
      end
    end
  end
end
