version Skyed::VERSION

desc 'Initialize skyed'
long_desc 'Sets up skyed configuration for a repository'

command :init do |cmd|
  cmd.flag [:remote], default_value: nil,
                      type: String,
                      desc: 'Remote to use in OpsWorks'
  cmd.flag [:repo], default_value: '.',
                    type: String,
                    desc: 'OpsWorks repository location'
  cmd.flag [:repo_key, 'repo-key'], default_value: nil,
                                    type: String,
                                    desc: 'Key to use with repo'
  cmd.flag [:j, :custom_json, 'custom-json'], default_value: '',
                                              type: String,
                                              desc: 'Custom JSON to pass to OW'
  desc = 'Chef version to use in OpsWorks'
  cmd.flag [:chef_version, 'chef-version'], default_value: '11.10',
                                            type: String,
                                            desc: desc
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
  desc = 'Time to wait for AWS responses'
  cmd.flag [:w, :wait_interval, 'wait-interval'], default_value: 30,
                                                  type: Integer,
                                                  desc: desc
  cmd.flag [:j, :custom_json, 'custom-json'], default_value: '',
                                              type: String,
                                              desc: 'Custom JSON to pass to OW'
  cmd.action do |global_options, options, args|
    Skyed::Run.execute(global_options, options, args)
  end
end

desc 'Destroy instance'
long_desc 'Destroy instance'

command :destroy do |cmd|
  cmd.switch [:rds], default_value: false,
                     desc: 'Destroys RDS instance'
  desc = 'Final snapshot name. Ommit to skip'
  cmd.flag [:final_snapshot_name, 'final-snapshot-name'], default_value: '',
                                                          type: String,
                                                          desc: desc
  cmd.action do |global_options, options, args|
    Skyed::Destroy.execute(global_options, options, args)
  end
end

desc 'Create instance'
long_desc 'Create instance'

command :create do |cmd|
  cmd.switch [:rds], default_value: false,
                     desc: 'Creates RDS instance'
  cmd.flag [:size], default_value: 100,
                    type: Integer,
                    desc: 'Size of the RDS instance'
  cmd.flag [:type], default_value: 'm1.large',
                    type: String,
                    desc: 'Type of the RDS instance'
  cmd.flag [:user], default_value: 'root',
                    type: String,
                    desc: 'Master user of the RDS instance'
  cmd.flag [:password], default_value: 'password',
                        type: String,
                        desc: 'Master password of the RDS instance'
  defval = 'default'
  desc = 'Name of the DB Security Group'
  cmd.flag [:db_security_group, 'db-security-group'], default_value: defval,
                                                      type: String,
                                                      desc: desc
  defval = 'default.postgres9.4'
  desc = 'Name of the DB Parameter Group'
  cmd.flag [:db_parameters_group, 'db-parameters-group'], default_value: defval,
                                                          type: String,
                                                          desc: desc
  cmd.action do |global_options, options, args|
    Skyed::Create.execute(global_options, options, args)
  end
end

desc 'List objects'
long_desc 'List objects'

command :list do |cmd|
  cmd.switch [:rds], default_value: false,
                     desc: 'Lists RDS objects'

  cmd.action do |global_options, options, args|
    Skyed::List.execute(global_options, options, args)
  end
end
