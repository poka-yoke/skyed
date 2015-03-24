desc 'Initialize skyed'
long_desc 'Sets up skyed configuration for a repository'

command :init do |cmd|
  cmd.action do |global_options|
    Skyed::Init.execute(global_options)
  end
end

desc 'Deploy current setup'
long_desc 'Deploys from current repository'

command :deploy do |cmd|
  cmd.flag :remote, default_value: nil,
                    type: String,
                    desc: 'Remote to use in OpsWorks'
  cmd.action do |global_options, options|
    Skyed::Deploy.execute(global_options, options)
  end
end
