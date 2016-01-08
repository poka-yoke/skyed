require 'thor'

module Skyed
  # Settings CLI for Skyed
  class Settings < Thor
    desc 'list', 'List Skyed settings'
    def list
      fail NotImplementedError
    end
  end
end
