require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Init.execute' do
  let(:repository) { double('repository') }
  let(:repo_path)  { double('repo_path') }
  let(:path)       { 'path' }
  before(:each) do
    allow(Skyed::Init)
      .to receive(:repo_path)
      .and_return(repo_path)
    allow(Skyed::Init)
      .to receive(:get_repo)
      .and_return(repository)
    allow(repo_path)
      .to receive(:to_s)
      .and_return(path)
    allow(Skyed::Init)
      .to receive(:branch)
      .and_return('devel-1')
    allow(Skyed::Init)
      .to receive(:credentials)
      .and_return(%w( 'a', 'a' ))
    allow(Skyed::Init)
      .to receive(:opsworks)
    allow(Skyed::Init)
      .to receive(:vagrant)
    allow(File)
      .to receive(:exist?)
      .and_return(true)
    allow(Skyed::Settings)
      .to receive(:save)
    allow(Skyed::Settings)
      .to receive(:empty?)
      .and_return(true)
  end
  it 'initializes skyed' do
    Skyed::Init.execute(nil)
  end
  it 'fails when already initialized' do
    allow(Skyed::Settings)
      .to receive(:empty?)
      .and_return(false)
    expect { Skyed::Init.execute(nil) }
      .to raise_error
  end
end

describe 'Skyed::Init.opsworks' do
  let(:opsworks)          { double('AWS::OpsWorks::Client') }
  let(:ow_stack_response) { double('Core::Response') }
  let(:ow_layer_response) { double('Core::Response') }
  let(:access)            { 'AKIAAKIAAKIA' }
  let(:secret)            { 'sGe84ofDSkfo' }
  let(:user)              { 'user' }
  let(:region)            { 'us-east-1' }
  let(:stack_id)          { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:stack_data)        { { stack_id: stack_id } }
  let(:layer_id)          { 'e1403a56-286e-4b5e-6798-c3406c947b4b' }
  let(:layer_data)        { { layer_id: layer_id } }
  let(:service_role_arn) do
    'arn:aws:iam::234098234027:role/aws-opsworks-service-role'
  end
  let(:instance_profile_arn) do
    'arn:aws:iam::234098234027:instance-profile/aws-opsworks-ec2-role'
  end
  before(:each) do
    @olduser = ENV['USER']
    ENV['USER'] = user
    allow(Skyed::Settings)
      .to receive(:access_key)
      .and_return(access)
    allow(Skyed::Settings)
      .to receive(:secret_key)
      .and_return(secret)
    allow(Skyed::Settings)
      .to receive(:role_arn)
      .and_return(service_role_arn)
    allow(Skyed::Settings)
      .to receive(:profile_arn)
      .and_return(instance_profile_arn)
    allow(Skyed::Settings)
      .to receive(:aws_key_name)
      .and_return('secret')
    allow(Skyed::Settings)
      .to receive(:git_url)
      .and_return('git@github.com:ifosch/repo')
    allow(Skyed::Settings)
      .to receive(:branch)
      .and_return('devel-1')
    allow(AWS::OpsWorks::Client)
      .to receive(:new)
      .with(access_key_id: access, secret_access_key: secret)
      .and_return(opsworks)
    expect(opsworks)
      .to receive(:create_stack)
      .with(
        name: user,
        region: region,
        service_role_arn: service_role_arn,
        default_instance_profile_arn: instance_profile_arn,
        default_os: 'Ubuntu 12.04 LTS',
        use_custom_cookbooks: true,
        custom_cookbooks_source: {
          url: 'git@github.com:ifosch/repo',
          # ssh_key: '',
          revision: 'devel-1',
          type: 'git'
        },
        default_ssh_key_name: 'secret',
        use_opsworks_security_groups: false)
      .and_return(ow_stack_response)
    allow(ow_stack_response)
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
    allow(ow_layer_response)
      .to receive(:data)
      .and_return(layer_data)
  end
  after(:each) do
    ENV['USER'] = @olduser
  end
  it 'sets up opsworks stack' do
    Skyed::Init.opsworks
    expect(Skyed::Settings.stack_id).to eq(stack_id)
    expect(Skyed::Settings.layer_id).to eq(layer_id)
  end
end

describe 'Skyed::Init.vagrant' do
  let(:repo_path)          { '/tmp/path' }
  let(:vagrantfile_erb)    { double('ERB') }
  let(:vagrantfile_handle) { double('File') }
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
    allow(ERB)
      .to receive(:new)
      .and_return(vagrantfile_erb)
    allow(vagrantfile_erb)
      .to receive(:result)
  end
  it 'sets vagrant up' do
    allow($CHILD_STATUS)
      .to receive(:success?)
      .and_return(true)
    allow(File)
      .to receive(:open)
      .and_return(vagrantfile_handle)
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
  let(:hash)       { '099f87e8090a09d' }
  let(:remote)     { double('Git::Remote') }
  let(:remote_url) { 'git@github.com/test/test.git' }
  let(:repository) { double('repository') }
  let(:repo_path)  { '/home/ifosch/projects/myrepo/.git' }
  let(:branch)     { double('branch') }
  before(:each) do
    allow(Skyed::Settings)
      .to receive(:repo)
      .and_return(repo_path)
    allow(Digest::SHA1)
      .to receive(:hexdigest)
      .and_return(hash)
    allow(Git)
      .to receive(:open)
      .with(repo_path)
      .and_return(repository)
    allow(repository)
      .to receive(:branch)
      .with("devel-#{hash}")
      .and_return(branch)
    allow(repository)
      .to receive(:remotes)
      .and_return([remote])
    allow(remote)
      .to receive(:url)
      .and_return(remote_url)
    allow(branch)
      .to receive(:checkout)
  end
  it 'calculates and creates the devel branch' do
    Skyed::Init.branch
    expect(Skyed::Settings.branch)
      .to eq("devel-#{hash}")
    expect(Skyed::Settings.git_url)
      .to eq('git@github.com/test/test.git')
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
