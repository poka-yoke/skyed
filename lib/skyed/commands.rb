desc 'Initialize skyed'
long_desc 'Sets up skyed configuration for a repository'

command :init do |cmd|
  cmd.flag :remote, default_value: nil,
                    type: String,
                    desc: 'Remote to use in OpsWorks'
  cmd.action do |global_options, options|
    Skyed::Init.execute(global_options, options)
  end
end

desc 'Deploy current setup'
long_desc 'Deploys from current repository'

command :deploy do |cmd|
  cmd.action do |global_options|
    Skyed::Deploy.execute(global_options)
  end
end

desc 'Run specific recipes on instance'
long_desc 'Runs specified recipes on all running instances'

stack_desc = 'Stack to which the run affects.'
layer_desc = 'Layer to which the run affects.'
command :run do |cmd|
  cmd.flag [:s, :stack], default_value: nil,
                         type: String,
                         desc: stack_desc
  cmd.flag [:l, :layer], default_value: nil,
                         type: String,
                         desc: layer_desc
  cmd.flag [:w, :wait_interval], default_value: 30,
                                 type: Integer,
                                 desc: 'Time to wait for AWS responses'
  cmd.flag [:j, :custom_json], default_value: '',
                               type: String,
                               desc: 'Custom JSON to pass to OW'
  cmd.action do |global_options, options, args|
    Skyed::Run.execute(global_options, options, args)
  end
end

desc 'Destroy instance'
long_desc 'Destroy instance'

command :destroy do |cmd|
  cmd.action do |global_options, options, args|
    Skyed::Destroy.execute(global_options, options, args)
  end
end
