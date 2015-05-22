require 'securerandom'

module Skyed
  # This module encapsulates all the Git features.
  module Git
    class << self
      def clone_stack_remote(stack)
        Skyed::Init.opsworks_git_key unless Skyed::Settings.current_stack?(
          stack[:stack_id])
        Skyed::Settings.opsworks_git_key
        "/tmp/skyed.#{SecureRandom.hex}"
      end
    end
  end
end
