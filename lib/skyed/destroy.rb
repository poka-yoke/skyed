module Skyed
  # This module encapsulates all the destroy command steps.
  module Destroy
    class << self
      def execute(global_options, options, args)
        Skyed::Init.credentials if Skyed::Settings.empty?
        destroy_vagrant(global_options, options, args) unless options[:rds]
        Skyed::AWS::RDS.destroy_instance(args[0], options) if options[:rds]
      end

      def destroy_vagrant(_global_options, _options, _args)
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
