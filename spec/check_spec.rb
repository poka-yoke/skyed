require 'spec_helper'
require 'skyed'

describe 'Skyed::Check.execute' do
  let(:ow)                    { double('Aws::OpsWorks::Client') }
  let(:elb)                   { double('Aws::ElastiLoadBalancing::Client') }
  let(:elb_name)              { 'ELB_name' }
  let(:instance_name)         { 'instance1' }
  let(:stack_id)              { '87654321-4321-4321-4321-210987654321' }
  let(:layer_id)              { '87654321-1234-4321-4321-210987654321' }
  let(:options)               { { stack: stack_id, layer: layer_id } }
  let(:args)                  { [elb_name, instance_name] }
  let(:original_health_check) { HealthCheck.new('HTTP:80', 20, 120, 5, 10) }
  context 'and initialized' do
    before(:each) do
      expect(Skyed::Check)
        .to receive(:settings)
        .with(options)
        .and_return(ow)
      expect(Skyed::Check)
        .to receive(:login)
        .and_return(elb)
      expect(Skyed::AWS::ELB)
        .to receive(:get_health_check)
        .with(elb_name, elb)
        .and_return(original_health_check)
      expect(Skyed::Check)
        .to receive(:reduce_health_check)
        .with(elb_name, original_health_check, elb)
      expect(Skyed::Check)
        .to receive(:wait_for_backend_restart)
        .with(elb_name, instance_name, options)
      expect(Skyed::AWS::ELB)
        .to receive(:set_health_check)
        .with(elb_name, original_health_check, elb)
    end
    it 'checks the ELB status' do
      Skyed::Check.execute(nil, options, args)
    end
  end
end

describe 'Skyed::Check.wait_for_backend_restart' do
  let(:ow)              { double('Aws::OpsWorks::Client') }
  let(:elb)             { double('Aws::ElastiLoadBalancing::Client') }
  let(:elb_name)        { 'ELB_name' }
  let(:instance_name)   { 'instance1' }
  let(:instance_id)     { '12345678-1234-1234-1234-123456789012' }
  let(:stack_id)        { '87654321-4321-4321-4321-210987654321' }
  let(:ec2_instance_id) { 'i-9876543' }
  let(:layer_id)        { '87654321-1234-4321-4321-210987654321' }
  let(:options)         { { stack: stack_id, layer: layer_id } }
  let(:instance1) do
    Instance.new(
      instance_id,
      instance_name,
      stack_id,
      [],
      'online',
      ec2_instance_id
    )
  end
  before(:each) do
    expect(Skyed::Check)
      .to receive(:settings)
      .with(options)
      .and_return(ow)
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .and_return(stack_id)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:instance_by_name)
      .with(instance_name, stack_id, ow)
      .and_return(instance1)
    expect(Skyed::Check)
      .to receive(:login)
      .with('elb')
      .and_return(elb)
    expect(Skyed::Check)
      .to receive(:wait_for_backend)
      .with(elb_name, ec2_instance_id, elb, false)
    expect(Skyed::Check)
      .to receive(:wait_for_backend)
      .with(elb_name, ec2_instance_id, elb)
  end
  it 'waits for the instance to restart' do
    Skyed::Check.wait_for_backend_restart(elb_name, instance_name, options)
  end
end

describe 'Skyed::Check.wait_for_backend' do
  let(:elb)             { double('Aws::ElastiLoadBalancing::Client') }
  let(:elb_name)        { 'ELB_name' }
  let(:ec2_instance_id) { 'i-9876543' }
  context 'when waiting for down' do
    before(:each) do
      expect(Skyed::AWS::ELB)
        .to receive(:instance_ok?)
        .with(elb_name, ec2_instance_id, elb)
        .once
        .and_return(true)
      expect(Skyed::AWS::ELB)
        .to receive(:instance_ok?)
        .with(elb_name, ec2_instance_id, elb)
        .at_least(1)
        .and_return(false)
    end
    it 'waits for the backend to be down' do
      Skyed::Check.wait_for_backend(elb_name, ec2_instance_id, elb, false)
    end
  end
  context 'when waiting for down' do
    before(:each) do
      expect(Skyed::AWS::ELB)
        .to receive(:instance_ok?)
        .with(elb_name, ec2_instance_id, elb)
        .once
        .and_return(false)
      expect(Skyed::AWS::ELB)
        .to receive(:instance_ok?)
        .with(elb_name, ec2_instance_id, elb)
        .once
        .and_return(true)
    end
    it 'waits for the backend to be up' do
      Skyed::Check.wait_for_backend(elb_name, ec2_instance_id, elb, true)
    end
  end
end

describe 'Skyed::Check.reduce_health_check' do
  let(:elb)                   { double('Aws::ElastiLoadBalancing::Client') }
  let(:elb_name)              { 'ELB_name' }
  let(:original_health_check) { HealthCheck.new('HTTP:80', 20, 120, 5, 10) }
  let(:new_health_check)      { HealthCheck.new('HTTP:80', 5, 2, 2, 2) }
  before(:each) do
    expect(Skyed::Check)
      .to receive(:login)
      .with('elb')
      .and_return(elb)
    expect(Skyed::AWS::ELB)
      .to receive(:set_health_check)
      .with(elb_name, new_health_check, elb)
  end
  it 'reduces the parameters of the health_check' do
    Skyed::Check.reduce_health_check(elb_name, original_health_check)
  end
end

describe 'Skyed::Check.settings' do
  let(:ow)       { double('Aws::OpsWorks::Client') }
  let(:stack_id) { '12345678-1234-1234-1234-123456789012' }
  let(:layer_id) { '87654321-4321-4321-4321-210987654321' }
  let(:options)  { { stack: stack_id, layer: layer_id } }
  let(:stack) do
    Stack.new(stack_id, 'Production')
  end
  let(:layer) do
    Layer.new(stack_id, layer_id, 'Web')
  end
  before(:each) do
    expect(Skyed::Check)
      .to receive(:login)
      .with('ow')
      .and_return(ow)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:stack)
      .with(stack_id, ow)
      .and_return(stack)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:layer)
      .with(layer_id, ow)
      .and_return(layer)
  end
  it 'sets up settings for the execution' do
    Skyed::Check.settings(options)
  end
end

describe 'Skyed::Check.login' do
  before(:each) do
    expect(Skyed::AWS::ELB)
      .to receive(:login)
  end
  context 'when initialized' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(true)
      expect(Skyed::Init)
        .to receive(:credentials)
    end
    it 'logs in' do
      Skyed::Check.login
    end
  end
  context 'and initialized' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(false)
      expect(Skyed::Init)
        .not_to receive(:credentials)
    end
    it 'logs in' do
      Skyed::Check.login
    end
  end
end
