module Skyed
  # This module encapsulates some generic utility functions.
  module Utils
    class << self
      def read_key_file(key_file)
        File.open(key_file, 'rb').read
      end
    end
  end
end
