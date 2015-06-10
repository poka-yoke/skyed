desc 'Initialize skyed'
long_desc 'Sets up skyed configuration for a repository'

command :init do |cmd|
  cmd.flag :remote, default_value: nil,
                    type: String,
                    desc: 'Remote to use in OpsWorks'
  cmd.flag :repo, default_value: '.',
                  type: String,
                  desc: 'OpsWorks repository location'
  cmd.flag :chef_version, default_value: '11.10',
                          type: String,
                          desc: 'Chef version to use in OpsWorks'
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
  cmd.switch :rds, default_value: false,
                   desc: 'Destroys RDS instance'
  cmd.flag :final_snapshot_name, default_value: '',
                                 type: String,
                                 desc: 'Final snapshot name. Ommit to skip'
  cmd.action do |global_options, options, args|
    Skyed::Destroy.execute(global_options, options, args)
  end
end

desc 'Create instance'
long_desc 'Create instance'

command :create do |cmd|
  cmd.switch :rds, default_value: false,
                   desc: 'Creates RDS instance'
  cmd.flag :size, default_value: 100,
                  type: Integer,
                  desc: 'Size of the RDS instance'
  cmd.flag :type, default_value: 'm1.large',
                  type: String,
                  desc: 'Type of the RDS instance'
  cmd.flag :user, default_value: 'root',
                  type: String,
                  desc: 'Master user of the RDS instance'
  cmd.flag :pass, default_value: 'password',
                  type: String,
                  desc: 'Master password of the RDS instance'
  cmd.flag :db_security_group_name, default_value: 'rds-launch-wizard',
                                    type: String,
                                    desc: 'Name of the DB Security Group'
  cmd.flag :db_parameters_group_name, default_value: 'default',
                                      type: String,
                                      desc: 'Name of the DB Parameter Group'
  cmd.action do |global_options, options, args|
    Skyed::Create.execute(global_options, options, args)
  end
end
