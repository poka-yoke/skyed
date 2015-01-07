module Skyed
  module Commands
    class Command
      @@commands = Hash.new(nil)

      def self.register name, description
        @@commands[name] = description
      end

      def self.getCommands
        @@commands
      end
    end
  end
end
