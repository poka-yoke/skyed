require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Init.credentials' do
  let(:access) { 'AKIAAKIAAKIA' }
  let(:secret) { 'sGe84ofDSkfo' }
  before(:each) do
    allow(ENV)
      .to receive(:[])
      .with('AWS_ACCESS_KEY')
      .and_return(access)
    allow(ENV)
      .to receive(:[])
      .with('AWS_SECRET_KEY')
      .and_return(secret)
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
