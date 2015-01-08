desc 'Initialize skyed'
long_desc 'Sets up skyed configuration for a repository'

command :init do |cmd|
  cmd.action do |global_options|
    Skyed::Init.execute(global_options)
  end
end
