require 'spec_helper'
require 'skyed'
require 'highline/import'

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
