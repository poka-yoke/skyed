module Skyed
  # This module encapsulates all the deploy command steps.
  module Deploy
    class << self
      def execute(global_options)
        fail 'Not initialized, please run skyed init' if Skyed::Settings.empty?
        Skyed::Utils.export_credentials
        push_devel_branch(global_options)
        output = `cd #{Skyed::Settings.repo} && vagrant up`
        fail output unless $CHILD_STATUS.success?
        $CHILD_STATUS.success?
      end

      def push_devel_branch(_global_options)
        repo = ::Git.open(Skyed::Settings.repo)
        repo.push(Skyed::Settings.remote_name, Skyed::Settings.branch)
      end
    end
  end
end
