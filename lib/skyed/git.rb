require 'securerandom'
require 'erb'

module Skyed
  # This module encapsulates all the Git features.
  module Git
    class << self
      def clone_stack_remote(stack)
        Skyed::Init.opsworks_git_key unless Skyed::Settings.current_stack?(
         stack[:stack_id])
        ENV['PKEY'] = Skyed::Settings.opsworks_git_key
        Skyed::Utils.create_template('/tmp', 'ssh-git', 'ssh-git.erb')
        File.chmod(0755, '/tmp/ssh-git')
        ENV['GIT_SSH'] = '/tmp/ssh-git'
        path = "/tmp/skyed.#{SecureRandom.hex}"
        ::Git.clone(stack[:custom_cookbooks_source][:url], path)
        path
      end
    end
  end
end
