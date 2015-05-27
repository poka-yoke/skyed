require 'erb'

module Skyed
  # This module encapsulates some generic utility functions.
  module Utils
    class << self
      def create_template(base, subpath, template_file)
        b = binding
        folders = subpath.split('/')
        template = ERB.new(
          File.read(File.join(
              File.dirname(File.dirname(File.dirname(__FILE__))),
              'templates',
              template_file)))
        File.open(File.join(base, folders), 'w') do |f|
          f.write(template.result b)
        end
      end

      def read_key_file(key_file)
        File.open(key_file, 'rb').read
      end
    end
  end
end
