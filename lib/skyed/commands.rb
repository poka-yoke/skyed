desc 'Initialize skyed'
long_desc 'Sets up skyed configuration for a repository'

command :init do |cmd|
  cmd.action do |global_options, options, args|
    Skyed::Init.execute(global_options)
  end
end
