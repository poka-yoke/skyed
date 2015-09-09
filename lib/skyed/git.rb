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
        chef_source = stack[:custom_cookbooks_source]
        `git clone --branch #{chef_source[:revision]} -- #{chef_source[:url]} #{path} GIT_SSH=/tmp/ssh-git`
        #::Git.clone(chef_source[:url], path, branch: chef_source[:revision])
        path
      end
    end
  end
end
