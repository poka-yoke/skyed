require 'thor'
require 'skyed'

module Skyed
  # Main CLI for Skyed
  class CLI < Thor
    desc 'settings', 'Manage Skyed settings'
    subcommand 'settings', Skyed::Settings
  end
end
