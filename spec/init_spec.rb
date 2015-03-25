require 'spec_helper'
require 'skyed'

describe 'Skyed::Init.execute' do
  let(:repository) { double('repository') }
  let(:repo_path)  { double('repo_path') }
  let(:path)       { 'path' }
  context 'when skyed is not initialized' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(true)
      expect(Skyed::Init)
        .to receive(:get_repo)
        .and_return(repository)
      expect(Skyed::Init)
        .to receive(:repo_path)
        .and_return(repo_path)
      expect(repo_path)
        .to receive(:to_s)
        .and_return(path)
      expect(Skyed::Init)
        .to receive(:credentials)
        .and_return(%w( 'a', 'a' ))
      expect(Skyed::Init)
        .to receive(:opsworks_git_key)
      expect(Skyed::Init)
        .to receive(:opsworks)
      expect(Skyed::Init)
        .to receive(:vagrant)
      expect(Skyed::Settings)
        .to receive(:save)
    end
    context 'without any option' do
      before(:each) do
        expect(Skyed::Init)
          .to receive(:branch)
          .with(nil, nil)
      end
      it 'initializes it' do
        Skyed::Init.execute(nil, nil)
      end
    end
  end
  context 'when skyed is already initialized' do
    it 'fails' do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(false)
      expect { Skyed::Init.execute(nil, nil) }
        .to raise_error
    end
  end
end

describe 'Skyed::Init.opsworks' do
  let(:opsworks)          { double('AWS::OpsWorks::Client') }
  let(:ow_stack_response) { double('Core::Response') }
  let(:ow_layer_response) { double('Core::Response') }
  let(:ow_git_key_file)   { '/home/user/.ssh/private_key' }
  let(:access)            { 'AKIAAKIAAKIA' }
  let(:secret)            { 'sGe84ofDSkfo' }
  let(:user)              { 'user' }
  let(:region)            { 'us-east-1' }
  let(:stack_id)          { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:stack_data)        { { stack_id: stack_id } }
  let(:layer_id)          { 'e1403a56-286e-4b5e-6798-c3406c947b4b' }
  let(:layer_data)        { { layer_id: layer_id } }
  let(:stack1)            { { stack_id: 1, name: 'Develop' } }
  let(:stack2)            { { stack_id: 2, name: 'Master' } }
  let(:stacks)            { { stacks: [stack1, stack2] } }
  let(:ow_git_key) do
    key = "-----BEGIN RSA PRIVATE KEY-----\n"
    key += "ASOCSSDCKLKJERLKJsdxljsdfLJKDSf\n"
    key += '-----END RSA PRIVATE KEY-----'
    key
  end
  let(:service_role_arn) do
    'arn:aws:iam::234098234027:role/aws-opsworks-service-role'
  end
  let(:instance_profile_arn) do
    'arn:aws:iam::234098234027:instance-profile/aws-opsworks-ec2-role'
  end
  before(:each) do
    @olduser = ENV['USER']
    ENV['USER'] = user
    expect(Skyed::Settings)
      .to receive(:opsworks_git_key)
      .and_return(ow_git_key_file)
    expect(Skyed::Init)
      .to receive(:read_key_file)
      .with(ow_git_key_file)
      .and_return(ow_git_key)
    expect(Skyed::Settings)
      .to receive(:access_key)
      .and_return(access)
    expect(Skyed::Settings)
      .to receive(:secret_key)
      .and_return(secret)
    expect(Skyed::Settings)
      .to receive(:role_arn)
      .and_return(service_role_arn)
    expect(Skyed::Settings)
      .to receive(:profile_arn)
      .and_return(instance_profile_arn)
    expect(Skyed::Settings)
      .to receive(:aws_key_name)
      .and_return('secret')
    expect(Skyed::Settings)
      .to receive(:remote_url)
      .and_return('git@github.com:ifosch/repo')
    expect(Skyed::Settings)
      .to receive(:branch)
      .and_return('devel-1')
    expect(AWS::OpsWorks::Client)
      .to receive(:new)
      .with(access_key_id: access, secret_access_key: secret)
      .and_return(opsworks)
    expect(opsworks)
      .to receive(:describe_stacks)
      .and_return(stacks)
  end
  after(:each) do
    ENV['USER'] = @olduser
  end
  context 'when stack does not exist' do
    before(:each) do
      expect(opsworks)
        .not_to receive(:describe_stack_summary)
      expect(opsworks)
        .to receive(:create_stack)
        .with(
          name: user,
          region: region,
          service_role_arn: service_role_arn,
          default_instance_profile_arn: instance_profile_arn,
          default_os: 'Ubuntu 12.04 LTS',
          configuration_manager: {
            name: 'Chef',
            version: '11.10'
          },
          use_custom_cookbooks: true,
          custom_cookbooks_source: {
            url: 'git@github.com:ifosch/repo',
            ssh_key: ow_git_key,
            revision: 'devel-1',
            type: 'git'
          },
          default_ssh_key_name: 'secret',
          use_opsworks_security_groups: false)
        .and_return(ow_stack_response)
      expect(ow_stack_response)
        .to receive(:data)
        .and_return(stack_data)
      expect(opsworks)
        .to receive(:create_layer)
        .with(
          stack_id: stack_id,
          type: 'custom',
          name: "test-#{user}",
          shortname: "test-#{user}",
          custom_security_group_ids: ['sg-f1cc2498'])
        .and_return(ow_layer_response)
      expect(ow_layer_response)
        .to receive(:data)
        .and_return(layer_data)
    end
    it 'sets up opsworks stack' do
      Skyed::Init.opsworks
      expect(Skyed::Settings.stack_id).to eq(stack_id)
      expect(Skyed::Settings.layer_id).to eq(layer_id)
    end
  end
  context 'when stack exists' do
    let(:stack3)          { { stack_id: 3, name: 'user' } }
    let(:stacks)          { { stacks: [stack1, stack2, stack3] } }
    context 'but contains no instances' do
      let(:instances_count) do
        {
          assigning: 0,
          booting: 0,
          connection_lost: 0,
          deregistering: 0,
          online: 0,
          pending: 0,
          rebooting: 0,
          registered: 0,
          registering: 0,
          requested: 0,
          running_setup: 0,
          setup_failed: 0,
          shutting_down: 0,
          start_failed: 0,
          stopped: 0,
          stopping: 0,
          terminated: 0,
          terminating: 0,
          unassigning: 0
        }
      end
      let(:stack3_summary) do
        { stack_summary: {
          stack_id: 3,
          name: 'user',
          instances_count: instances_count } }
      end
      before(:each) do
        expect(opsworks)
          .to receive(:describe_stack_summary)
          .with(stack_id: 3)
          .and_return(stack3_summary)
        expect(opsworks)
          .to receive(:delete_stack)
          .with(stack_id: 3)
        expect(Skyed::Init)
          .to receive(:vagrantfile)
          .at_least(1).times
          .and_return('Vagrantfile')
        expect(File)
          .to receive(:exist?)
          .with('Vagrantfile')
          .and_return(true)
        expect(File)
          .to receive(:delete)
          .with('Vagrantfile')
        expect(opsworks)
          .to receive(:create_stack)
          .with(
            name: user,
            region: region,
            service_role_arn: service_role_arn,
            default_instance_profile_arn: instance_profile_arn,
            default_os: 'Ubuntu 12.04 LTS',
            configuration_manager: {
              name: 'Chef',
              version: '11.10'
            },
            use_custom_cookbooks: true,
            custom_cookbooks_source: {
              url: 'git@github.com:ifosch/repo',
              ssh_key: ow_git_key,
              revision: 'devel-1',
              type: 'git'
            },
            default_ssh_key_name: 'secret',
            use_opsworks_security_groups: false)
          .and_return(ow_stack_response)
        expect(ow_stack_response)
          .to receive(:data)
          .and_return(stack_data)
        expect(opsworks)
          .to receive(:create_layer)
          .with(
            stack_id: stack_id,
            type: 'custom',
            name: "test-#{user}",
            shortname: "test-#{user}",
            custom_security_group_ids: ['sg-f1cc2498'])
          .and_return(ow_layer_response)
        expect(ow_layer_response)
          .to receive(:data)
          .and_return(layer_data)
      end
      it 'sets up opsworks stack' do
        Skyed::Init.opsworks
        expect(Skyed::Settings.stack_id).to eq(stack_id)
        expect(Skyed::Settings.layer_id).to eq(layer_id)
      end
    end
    context 'but contains instances' do
      let(:instances_count) do
        {
          assigning: 1,
          booting: 0,
          connection_lost: 0,
          deregistering: 0,
          online: 0,
          pending: 0,
          rebooting: 0,
          registered: 0,
          registering: 0,
          requested: 0,
          running_setup: 0,
          setup_failed: 0,
          shutting_down: 0,
          start_failed: 0,
          stopped: 0,
          stopping: 0,
          terminated: 0,
          terminating: 0,
          unassigning: 0
        }
      end
      let(:stack3_summary) do
        { stack_summary: {
          stack_id: 3,
          name: 'user',
          instances_count: instances_count } }
      end
      before(:each) do
        expect(opsworks)
          .to receive(:describe_stack_summary)
          .with(stack_id: 3)
          .and_return(stack3_summary)
        expect(opsworks)
          .not_to receive(:delete_stack)
          .with(stack_id: 3)
        expect(opsworks)
          .not_to receive(:create_stack)
      end
      it 'sets up opsworks stack' do
        expect { Skyed::Init.opsworks }
          .to raise_error
      end
    end
  end
end

describe 'Skyed::Init.vagrant' do
  let(:repo_path)          { '/tmp/path' }
  let :provisioning_path do
    File.join(
      repo_path,
      '.provisioning')
  end
  let(:templates_path) do
    File.join(
      provisioning_path,
      'templates',
      'aws')
  end
  let(:tasks_path) do
    File.join(
      provisioning_path,
      'tasks')
  end
  before(:each) do
    allow(Skyed::Init)
      .to receive(:`)
    allow(Skyed::Settings)
      .to receive(:repo)
      .and_return(repo_path)
    allow(FileUtils)
      .to receive(:mkdir_p)
      .with(templates_path)
    allow(FileUtils)
      .to receive(:mkdir_p)
      .with(tasks_path)
    expect(Skyed::Init)
      .to receive(:create_template)
      .with(
        repo_path,
        'Vagrantfile',
        'templates/Vagrantfile.erb')
    expect(Skyed::Init)
      .to receive(:create_template)
      .with(
        File.join(repo_path, '.provisioning', 'tasks'),
        'ow-on-premise.yml',
        'templates/ow-on-premise.yml.erb')
    expect(Skyed::Init)
      .to receive(:create_template)
      .with(
        File.join(repo_path, '.provisioning', 'templates', 'aws'),
        'config.j2',
        'templates/config.j2.erb')
    expect(Skyed::Init)
      .to receive(:create_template)
      .with(
        File.join(repo_path, '.provisioning', 'templates', 'aws'),
        'credentials.j2',
        'templates/credentials.j2.erb')
  end
  it 'sets vagrant up' do
    allow($CHILD_STATUS)
      .to receive(:success?)
      .and_return(true)
    Skyed::Init.vagrant
  end
end

describe 'Skyed::Init.pip_install' do
  before(:each) do
    expect(Skyed::Init)
      .to receive(:`)
      .with('pip list | grep package')
    allow(Skyed::Init)
      .to receive(:`)
      .with('which pip')
    allow(Skyed::Init)
      .to receive(:easy_install)
      .with('pip')
    allow(Skyed::Init)
      .to receive(:`)
      .with('sudo pip install package')
    allow($CHILD_STATUS)
      .to receive(:success?)
      .and_return(false)
  end
  it 'installs package' do
    expect($CHILD_STATUS)
      .to receive(:success?)
      .and_return(true)
    Skyed::Init.pip_install 'package'
  end
  it 'fails on install package' do
    expect($CHILD_STATUS)
      .to receive(:success?)
      .and_return(false)
    expect { Skyed::Init.pip_install 'package' }
      .to raise_error
  end
end

describe 'Skyed::Init.easy_install' do
  before(:each) do
    expect(Skyed::Init)
      .to receive(:`)
      .once
      .with('easy_install package')
  end
  it 'installs package' do
    expect($CHILD_STATUS)
      .to receive(:success?)
      .and_return(true)
    Skyed::Init.easy_install 'package'
  end
  it 'fails on install package' do
    expect($CHILD_STATUS)
      .to receive(:success?)
      .and_return(false)
    expect { Skyed::Init.easy_install 'package' }
      .to raise_error
  end
end

describe 'Skyed::Init.valid_credential?' do
  before(:all) do
    ENV['SKYED1'] = 'test'
    ENV['SKYED2'] = ''
    ENV['SKYED3'] = nil
  end
  it 'validates normal environment variable' do
    expect(Skyed::Init.valid_credential?('SKYED1'))
      .to eq(true)
    expect(Skyed::Init.valid_credential?('SKYED2'))
      .to eq(false)
    expect(Skyed::Init.valid_credential?('SKYED3'))
      .to eq(false)
  end
end

describe 'Skyed::Init.branch' do
  context 'invoked without any option' do
    let(:remote_name) { 'name' }
    let(:remote_url)  { 'git@github.com/test/test.git' }
    let(:hash)        { '099f87e8090a09d' }
    let(:repository)  { double('repository') }
    let(:repo_path)   { '/home/ifosch/projects/myrepo/.git' }
    let(:branch)      { double('branch') }
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:repo)
        .twice
        .and_return(repo_path)
      expect(Digest::SHA1)
        .to receive(:hexdigest)
        .and_return(hash)
      expect(Git)
        .to receive(:open)
        .with(repo_path)
        .and_return(repository)
      expect(repository)
        .to receive(:branch)
        .with("devel-#{hash}")
        .and_return(branch)
      expect(branch)
        .to receive(:checkout)
      expect(Skyed::Init)
        .to receive(:git_remote_data)
        .with(repository, nil, nil)
        .and_return(name: remote_name, url: remote_url)
    end
    it 'calculates and creates the devel branch' do
      Skyed::Init.branch(nil, nil)
      expect(Skyed::Settings.branch)
        .to eq("devel-#{hash}")
      expect(Skyed::Settings.remote_name)
        .to eq('name')
      expect(Skyed::Settings.remote_url)
        .to eq('git@github.com/test/test.git')
    end
  end
end

describe 'Skyed::Init.git_remote_data' do
  let(:remote1)      { double('Git::Remote') }
  let(:remote1_name) { 'name' }
  let(:remote1_url)  { 'git@github.com/test/test.git' }
  let(:repository)   { double('repository') }
  before(:each) do
    allow(remote1)
      .to receive(:name)
      .and_return(remote1_name)
    allow(remote1)
      .to receive(:url)
      .and_return(remote1_url)
  end
  context 'without specifying the remote option' do
    context 'with just one remote' do
      let(:remotes)     { [remote1] }
      before(:each) do
        expect(remote1)
          .to receive(:name)
          .and_return(remote1_name)
        expect(remote1)
          .to receive(:url)
          .and_return(remote1_url)
        expect(repository)
          .to receive(:remotes)
          .at_least(3).times
          .and_return(remotes)
      end
      it 'stores the name and url of the remote' do
        expect(Skyed::Init.git_remote_data(repository, nil, {}))
          .to eq(name: 'name', url: 'git@github.com/test/test.git')
      end
    end
    context 'with two remotes' do
      let(:remote2)      { double('Git::Remote') }
      let(:remote2_name) { 'name2' }
      let(:remote2_url)  { 'git@github.com/test2/test.git' }
      before(:each) do
        expect(remote2)
          .to receive(:name)
          .at_least(2).times
          .and_return(remote2_name)
        expect(remote2)
          .to receive(:url)
          .and_return(remote2_url)
        expect(repository)
          .to receive(:remotes)
          .at_least(3).times
          .and_return([remote1, remote2])
        expect(Skyed::Init)
          .to receive(:ask_remote_name)
          .with([remote1_name, remote2_name])
          .and_return(remote2_name)
      end
      it 'stores the name and url of the chosen remote' do
        expect(Skyed::Init.git_remote_data(repository, nil, {}))
          .to eq(name: 'name2', url: 'git@github.com/test2/test.git')
      end
    end
  end
  context 'when specifying a remote in the options' do
    context 'and that remote exists' do
      let(:remote2)      { double('Git::Remote') }
      let(:remote2_name) { 'origin' }
      let(:remote2_url)  { 'git@github.com/origin/test.git' }
      before(:each) do
        expect(remote2)
          .to receive(:name)
          .and_return(remote2_name)
        expect(remote2)
          .to receive(:url)
          .and_return(remote2_url)
        expect(repository)
          .to receive(:remotes)
          .at_least(2).times
          .and_return([remote1, remote2])
        expect(Skyed::Init)
          .not_to receive(:ask_remote_name)
      end
      it 'stores the name and url of the remote' do
        expect(Skyed::Init.git_remote_data(repository, nil, remote: 'origin'))
          .to eq(name: 'origin', url: 'git@github.com/origin/test.git')
      end
    end
    context 'and that remote does not exist' do
      let(:remote2)      { double('Git::Remote') }
      let(:remote2_name) { 'origin2' }
      let(:remote2_url)  { 'git@github.com/origin/test.git' }
      before(:each) do
        expect(remote2)
          .to receive(:name)
          .and_return(remote2_name)
        allow(remote2)
          .to receive(:url)
          .and_return(remote2_url)
        expect(repository)
          .to receive(:remotes)
          .at_least(2).times
          .and_return([remote1, remote2])
        expect(Skyed::Init)
          .not_to receive(:ask_remote_name)
      end
      it 'stores the name and url of the first remote' do
        expect(Skyed::Init.git_remote_data(repository, nil, remote: 'origin'))
          .to eq(name: 'name', url: 'git@github.com/test/test.git')
      end
    end
  end
end

describe 'Skyed::Init.credentials' do
  let(:opsworks)       { double('AWS::OpsWorks::Client') }
  let(:access)         { 'AKIAAKIAAKIA' }
  let(:secret)         { 'sGe84ofDSkfo' }
  let(:aws_key_name)   { 'keypair' }
  let(:sra) do
    'arn:aws:iam::123098345737:role/aws-opsworks-service-role'
  end
  let(:ipa) do
    'arn:aws:iam::234098345717:instance-profile/aws-opsworks-ec2-role'
  end
  before(:each) do
    @oldaccess                 = ENV['AWS_ACCESS_KEY']
    @oldsecret                 = ENV['AWS_SECRET_KEY']
    @oldaws_ssh_key_name       = ENV['AWS_SSH_KEY_NAME']
    @oldservice_role           = ENV['OW_SERVICE_ROLE']
    @oldinstance_profile       = ENV['OW_INSTANCE_PROFILE']
    ENV['AWS_ACCESS_KEY']      = access
    ENV['AWS_SECRET_KEY']      = secret
    ENV['AWS_SSH_KEY_NAME']    = aws_key_name
    ENV['OW_SERVICE_ROLE']     = sra
    ENV['OW_INSTANCE_PROFILE'] = ipa
    expect(AWS::OpsWorks::Client)
      .to receive(:new)
      .with(access_key_id: access, secret_access_key: secret)
      .and_return(opsworks)
  end
  after(:each) do
    ENV['AWS_ACCESS_KEY']      = @oldaccess
    ENV['AWS_SECRET_KEY']      = @oldsecret
    ENV['AWS_SSH_KEY_NAME']    = @oldaws_ssh_key_name
    ENV['OW_SERVICE_ROLE']     = @oldservice_role
    ENV['OW_INSTANCE_PROFILE'] = @oldinstance_profile
  end
  it 'recovers credentials from environment variables' do
    Skyed::Init.credentials
    expect(Skyed::Settings.access_key)
      .to eq(access)
    expect(Skyed::Settings.secret_key)
      .to eq(secret)
    expect(Skyed::Settings.aws_key_name)
      .to eq(aws_key_name)
    expect(Skyed::Settings.role_arn)
      .to eq(sra)
    expect(Skyed::Settings.profile_arn)
      .to eq(ipa)
  end
end

describe 'Skyed::Init.repo_path' do
  let(:repo_path)  { '/home/ifosch/projects/myrepo/.git' }
  let(:path)       { Pathname.new('/home/ifosch/projects/myrepo') }
  let(:repo)       { double('repo') }
  let(:repository) { double('repository') }
  before(:each) do
    allow(repo)
      .to receive(:path)
      .and_return(repo_path)
    allow(repository)
      .to receive(:repo)
      .and_return(repo)
  end
  it 'returns the path to the repository' do
    expect(Skyed::Init.repo_path(repository))
      .to eq(path)
  end
end

describe 'Skyed::Init.repo?' do
  let(:path1)      { double('String') }
  let(:path2)      { double('String') }
  let(:repository) { double('repository') }
  before(:each) do
    allow(Git)
      .to receive(:open)
      .with(path1)
      .and_return(repository)
    allow(Git)
      .to receive(:open)
      .with(path2)
      .and_raise(ArgumentError)
  end
  it 'returns the repository at path' do
    expect(Skyed::Init.repo?(path1))
      .to eq(repository)
  end
  it 'returns false when path is not a repository' do
    expect(Skyed::Init.repo?(path2))
      .to eq(false)
  end
end
