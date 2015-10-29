module Skyed
  # This module encapsulates all the destroy command steps.
  module Stop
    class << self
      def execute(_global_options, options, args)
        Skyed::Init.credentials if Skyed::Settings.empty?
        ow = Skyed::AWS::OpsWorks.login
        stack_id = Skyed::AWS::OpsWorks.stack(
          options[:stack], ow)[:stack_id]
        Skyed::AWS::OpsWorks.stop_instance(stack_id, args[0], ow)
      end
    end
  end
end
