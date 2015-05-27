module Skyed
  # This module encapsulates all the destroy command steps.
  module Destroy
    class << self
      def execute(_global_options, _options, _args)
        repo_path = Skyed::Settings.repo
        hostname = `cd #{repo_path} && vagrant ssh -c hostname`.strip
        `cd #{repo_path} && vagrant destroy -f`
        ow = Skyed::AWS::OpsWorks.login
        Skyed::AWS::OpsWorks.deregister_instance hostname, ow
        Skyed::AWS::OpsWorks.delete_user ow
      end
    end
  end
end
