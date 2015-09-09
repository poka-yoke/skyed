require 'securerandom'
require 'erb'

module Skyed
  # This module encapsulates all the Git features.
  module Git
    class << self
      def clone_cmd(stack, path)
        cmd = 'export GIT_SSH=/tmp/ssh-git; '
        cmd += 'git clone --branch '
        cmd += stack[:custom_cookbooks_source][:revision]
        cmd += " #{stack[:custom_cookbooks_source][:url]} "
        cmd += path
        cmd
      end

      def clone_stack_remote(stack, options)
        unless Skyed::Settings.current_stack?(stack[:stack_id])
          Skyed::Init.opsworks_git_key options
        end
        ENV['PKEY'] ||= Skyed::Settings.opsworks_git_key
        Skyed::Utils.create_template('/tmp', 'ssh-git', 'ssh-git.erb', 0755)
        path = "/tmp/skyed.#{SecureRandom.hex}"
        `#{clone_cmd(stack, path)}`
        path
      end
    end
  end
end
