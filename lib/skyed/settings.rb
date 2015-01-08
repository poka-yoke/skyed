module Skyed
  # This module contains all the config file related stuff
  module Settings
    CONFIG_FILE = "#{ENV['HOME']}/.skyed"
    @_settings = {}
    attr_accessor :_settings

    def load!(filename = CONFIG_FILE)
      newsets = {}
      newsets = YAML.load_file(filename) if File.file? filename
      deep_merge!(@_settings, newsets)
    end
    module_function :load!

    def empty?
      @_settings.empty?
    end
    module_function :empty?

    def deep_merge!(target, data)
      merger = proc do |_, v1, v2|
        v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2
      end
      target.merge! data, &merger
    end
    module_function :deep_merge!

    def method_missing(name, *args)
      if name.match(/.*=/)
        @_settings[name.to_s.split('=')[0]] = args[0]
      else
        @_settings[name.to_s] ||
          fail(NoMethodError, "unknown configuration root #{name}", caller)
      end
    end
    module_function :method_missing

    def save(filename = CONFIG_FILE)
      File.open(filename, 'w') { |f| YAML.dump @_settings, f }
    end
    module_function :save
  end
end
