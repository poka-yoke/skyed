module Skyed
  # This module encapsulates all the destroy command steps.
  module Destroy
    class << self
      def execute(_global_options, _options, _args)
        `cd #{Skyed::Settings.repo} && vagrant destroy -f`
      end
    end
  end
end
