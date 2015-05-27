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
        Skyed::AWS::OpsWorks.delete_user ow
      end

      # TODO: Move to Skyed::AWS::OpsWorks
      def deregister_instance(hostname, ow)
        instance = Skyed::AWS::OpsWorks.instance_by_name(
          hostname, Skyed::Settings.stack_id, ow)
        ow.deregister_instance(
          instance_id: instance.instance_id) unless instance.nil?
        Skyed::AWS::OpsWorks.wait_for_instance(
          hostname, Skyed::Settings.stack_id, 'terminated', ow)
      end
    end
  end
end
