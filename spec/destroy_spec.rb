require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Destroy.execute' do
  let(:opsworks)    { double('Aws::OpsWorks::Client') }
  let(:repo_path)   { '/home/ifosch/opsworks' }
  let(:hostname)    { 'test-ifosch' }
  let(:stack_id)    { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:instance_id) { '12345678-1234-4321-5678-210987654321' }
  let(:instance_online) do
    {
      instance_id: instance_id,
      hostname: hostname,
      stack_id: stack_id,
      status: 'online'
    }
  end
  let(:instance_shutting) do
    {
      instance_id: instance_id,
      hostname: hostname,
      stack_id: stack_id,
      status: 'shutting_down'
    }
  end
  let(:instance_term) do
    {
      instance_id: instance_id,
      hostname: hostname,
      stack_id: stack_id,
      status: 'terminated'
    }
  end
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:repo)
      .and_return(repo_path)
    expect(Skyed::Destroy)
      .to receive(:`)
      .with("cd #{repo_path} && vagrant ssh -c hostname")
      .and_return(hostname)
    expect(Skyed::Destroy)
      .to receive(:`)
      .with("cd #{repo_path} && vagrant destroy -f")
    expect(Skyed::AWS::OpsWorks)
      .to receive(:login)
      .and_return(opsworks)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:deregister_instance)
      .with(hostname, opsworks)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:delete_user)
      .with(opsworks)
  end
  it 'destroys the vagrant machine' do
    Skyed::Destroy.execute(nil, nil, nil)
  end
end
