require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Destroy.execute' do
  let(:opsworks)    { double('AWS::OpsWorks::Client') }
  let(:repo_path)   { '/home/ifosch/opsworks' }
  let(:hostname)    { 'test-ifosch' }
  let(:stack_id)    { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:instance_id) { '12345678-1234-4321-5678-210987654321' }
  let(:instances) do
    { instances: [{
      instance_id: instance_id,
      hostname: hostname,
      stack_id: stack_id
    }] }
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
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .and_return(stack_id)
    expect(opsworks)
      .to receive(:describe_instances)
      .with(stack_id: stack_id)
      .and_return(instances)
    expect(opsworks)
      .to receive(:deregister_instance)
      .with(instance_id: instance_id)
  end
  it 'destroys the vagrant machine' do
    Skyed::Destroy.execute(nil, nil, nil)
  end
end
