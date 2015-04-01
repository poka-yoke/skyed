module Skyed
  # This module encapsulates all the destroy command steps.
  module Destroy
    class << self
      def execute(_global_options, _options, _args)
        repo_path = Skyed::Settings.repo
        hostname = `cd #{repo_path} && vagrant ssh -c hostname`.strip
        `cd #{repo_path} && vagrant destroy -f`
        ow = Skyed::Init.ow_client
        instances = ow.describe_instances(stack_id: Skyed::Settings.stack_id)
        instances[:instances].each do |instance|
          if instance[:hostname] == hostname
            ow.deregister_instance(instance_id: instance[:instance_id])
          end
        end
      end
    end
  end
end
