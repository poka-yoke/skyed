
module Skyed
  module Settings
    extend self

    CONFIG_FILE = "#{ENV['HOME']}/.skyed"
    @_settings = {}
    attr_accessor :_settings

    def load!(filename = CONFIG_FILE)
      newsets = {}
      newsets = YAML::load_file(filename) if File.file? filename
      deep_merge!(@_settings, newsets)
    end

    def empty?
      @_settings.empty?
    end

    def deep_merge!(target, data)
      merger = proc{|key, v1, v2|
        Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      target.merge! data, &merger
    end

    def method_missing(name, *args, &block)
      if name.match(/.*=/) then
        @_settings[name.to_s.split('=')[0]] = args[0]
      else
        @_settings[name.to_s] ||
        fail(NoMethodError, "unknown configuration root #{name}", caller)
      end
    end

    def save(filename = CONFIG_FILE)
      File.open(filename,'w') { |f| YAML.dump @_settings, f }
    end
  end
end
