require 'securerandom'
require 'erb'

module Skyed
  # This module encapsulates all the Git features.
  module Git
    class << self
      def clone_stack_remote(stack, options)
        unless Skyed::Settings.current_stack?(stack[:stack_id])
          Skyed::Init.opsworks_git_key options
        end
        ENV['PKEY'] ||= Skyed::Settings.opsworks_git_key
        Skyed::Utils.create_template('/tmp', 'ssh-git', 'ssh-git.erb', 0755)
        ENV['GIT_SSH'] = '/tmp/ssh-git'
        path = "/tmp/skyed.#{SecureRandom.hex}"
        r = ::Git.clone(stack[:custom_cookbooks_source][:url], path)
        puts repo_path(r)
        path
      end
    end
  end
end
