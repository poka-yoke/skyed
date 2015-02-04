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
  let(:repository) { double('repository') }
  let(:branch)     { double('branch') }
  let(:repo_path)  { '/home/ifosch/projects/myrepo/.git' }
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
    allow(branch)
      .to receive(:checkout)
  end
  it 'calculates and creates the devel branch' do
    expect(Skyed::Init.branch)
      .to eq("devel-#{hash}")
  end
end

describe 'Skyed::Init.credentials' do
  let(:opsworks) { double('AWS::OpsWorks') }
  let(:access)   { 'AKIAAKIAAKIA' }
  let(:secret)   { 'sGe84ofDSkfo' }
  before(:each) do
    @oldaccess = ENV['AWS_ACCESS_KEY']
    @oldsecret = ENV['AWS_SECRET_KEY']
    ENV['AWS_ACCESS_KEY'] = access
    ENV['AWS_SECRET_KEY'] = secret
    expect(AWS::OpsWorks)
      .to receive(:new)
      .with(access_key_id: access, secret_access_key: secret)
      .and_return(opsworks)
  end
  after(:each) do
    ENV['AWS_ACCESS_KEY'] = @oldaccess
    ENV['AWS_SECRET_KEY'] = @oldsecret
  end
  it 'recovers credentials from environment variables' do
    expect(Skyed::Init.credentials)
      .to eq([access, secret])
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
