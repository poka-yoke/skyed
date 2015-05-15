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
    expect(Skyed::Destroy)
      .to receive(:deregister_instance)
      .with(hostname, opsworks)
    # expect(Skyed::Settings)
    #   .to receive(:stack_id)
    #   .at_least(1)
    #   .and_return(stack_id)
    # expect(Skyed::AWS::OpsWorks)
    #   .to receive(:instance_by_name)
    #   .with(hostname, stack_id, opsworks)
    #   .once
    #   .and_return(instance_online)
    # expect(opsworks)
    #   .to receive(:deregister_instance)
    #   .with(instance_id: instance_id)
    # expect(Skyed::Destroy)
    #   .to receive(:wait_for_instance)
    #   .with(hostname, stack_id, opsworks)
    expect(Skyed::Destroy)
      .to receive(:delete_user)
  end
  it 'destroys the vagrant machine' do
    Skyed::Destroy.execute(nil, nil, nil)
  end
end

describe 'Skyed::Destroy.deregister_insatance' do
  let(:opsworks)    { double('Aws::OpsWorks::Client') }
  let(:hostname)    { 'test-ifosch' }
  let(:stack_id)    { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:instance_id) { '12345678-1234-4321-5678-210987654321' }
  let(:instance_online) do
    Instance.new(
      instance_id,
      hostname,
      stack_id,
      'online'
    )
  end
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .at_least(1)
      .and_return(stack_id)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:instance_by_name)
      .with(hostname, stack_id, opsworks)
      .once
      .and_return(instance_online)
    expect(opsworks)
      .to receive(:deregister_instance)
      .with(instance_id: instance_id)
    expect(Skyed::Destroy)
      .to receive(:wait_for_instance)
      .with(hostname, stack_id, opsworks)
  end
  it 'deregisters the vagrant machine' do
    Skyed::Destroy.deregister_instance(hostname, opsworks)
  end
end

describe 'Skyed::Destroy.delete_user' do
  let(:opsworks)   { double('Aws::OpsWorks::Client') }
  let(:stack_id)   { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:stack_name) { 'stack' }
  let(:layer_id)   { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:layer_name) { 'layer' }
  let(:stack) do
    {
      stack_id: stack_id,
      name: stack_name
    }
  end
  let(:layer) do
    {
      layer_id: layer_id,
      name: layer_name
    }
  end
  before do
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .at_least(1)
      .and_return(stack_id)
    expect(opsworks)
      .to receive(:describe_stacks)
      .with(stack_ids: [stack_id])
      .and_return(stacks: [stack])
    expect(Skyed::Settings)
      .to receive(:layer_id)
      .and_return(layer_id)
    expect(opsworks)
      .to receive(:describe_layers)
      .with(layer_ids: [layer_id])
      .and_return(layers: [layer])
    expect(Skyed::AWS::IAM)
      .to receive(:delete_user)
      .with('OpsWorks-stack-layer')
  end
  it 'deletes user for deploy' do
    Skyed::Destroy.delete_user opsworks
  end
end

describe 'Skyed::Destroy.wait_for_instance' do
  let(:opsworks)    { double('Aws::OpsWorks::Client') }
  let(:hostname)    { 'test-ifosch' }
  let(:stack_id)    { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:instance_id) { '12345678-1234-4321-5678-210987654321' }
  let(:instance_shutting) do
    Instance.new(
      instance_id,
      hostname,
      stack_id,
      'shutting_down'
    )
  end
  let(:instance_term) do
    Instance.new(
      instance_id,
      hostname,
      stack_id,
      'terminated'
    )
  end
  before(:each) do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:instance_by_name)
      .with(hostname, stack_id, opsworks)
      .once
      .and_return(instance_shutting)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:instance_by_name)
      .with(hostname, stack_id, opsworks)
      .and_return(instance_term)
  end
  it 'waits until instance is unregistered' do
    Skyed::Destroy.wait_for_instance(hostname, stack_id, opsworks)
  end
end
