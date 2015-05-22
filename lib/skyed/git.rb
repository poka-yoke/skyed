require 'securerandom'

module Skyed
  # This module encapsulates all the Git features.
  module Git
    class << self
      def clone_stack_remote(stack)
        # TODO: Comment out when INF-865 is completed
        # Skyed::Init.opsworks_git_key unless Skyed::Settings.current_stack?(
        #  stack[:stack_id])
        # key = Skyed::Settings.opsworks_git_key
        path = "/tmp/skyed.#{SecureRandom.hex}"
        ::Git.clone(stack[:custom_cookbooks_source][:url], path)
        path
      end
    end
  end
end
