module Skyed
  # This module encapsulates all the deploy command steps.
  module Deploy
    def self.execute(_global_options)
      fail 'Not initialized, please run skyed init' if Skyed::Settings.empty?
      output = `cd #{Skyed::Settings.repo} && vagrant up`
      fail output unless $CHILD_STATUS.success?
      $CHILD_STATUS.success?
    end
  end
end
