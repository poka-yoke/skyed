require 'spec_helper'

describe 'Skyed::Git.clone_stack_remote' do
  let(:random)     { '5b5cd0da3121fc53b4bc84d0c8af2e81' }
  let(:clone_path) { '/tmp/skyed.5b5cd0da3121fc53b4bc84d0c8af2e81' }
  let(:key_path)   { '/home/.ssh/gitkey' }
  let(:stack_id)   { '12345678-1234-1234-1234-123456789012' }
  let(:url)        { 'git@github.com:/user/repo.git' }
  let(:options)    { { stack: stack_id } }
  let(:stack) do
    {
      stack_id: stack_id,
      name: 'test2',
      custom_cookbooks_source: {
        type: 'git',
        url: url,
        username: 'user',
        revision: 'master'
      }
    }
  end
  before(:each) do
    expect(SecureRandom)
      .to receive(:hex)
      .and_return(random)
    expect(Skyed::Utils)
      .to receive(:create_template)
      .with('/tmp', 'ssh-git', 'ssh-git.erb', 0755)
    expect(::Git)
      .to receive(:clone)
      .with(url, clone_path, branch: 'master')
  end
  context 'when is the current stack' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:current_stack?)
        .with(stack_id)
        .and_return(true)
      expect(Skyed::Settings)
        .to receive(:opsworks_git_key)
        .and_return(key_path)
    end
    it 'clones the stack remote and returns the path to it' do
      expect(Skyed::Git.clone_stack_remote(stack, options))
        .to eq(clone_path)
    end
  end
  context 'when is not the current stack' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:current_stack?)
        .with(stack_id)
        .and_return(false)
      expect(Skyed::Init)
        .to receive(:opsworks_git_key)
        .with(options)
    end
    it 'clones the stack remote and returns the path to it' do
      expect(Skyed::Git.clone_stack_remote(stack, options))
        .to eq(clone_path)
    end
  end
end
