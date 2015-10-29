require 'spec_helper'
require 'skyed'

describe 'Skyed::AWS.region' do
  let(:default_region) { 'us-east-1' }
  context 'when no environment variable is set' do
    before do
      expect(ENV)
        .to receive(:[])
        .with('AWS_DEFAULT_REGION')
        .and_return(nil)
    end
    it 'uses the default region' do
      expect(Skyed::AWS.region)
        .to eq(default_region)
    end
  end
  context 'when environment variable is set' do
    let(:another_region) { 'zMLdko39fj' }
    before(:each) do
      expect(ENV)
        .to receive(:[])
        .with('AWS_DEFAULT_REGION')
        .and_return(another_region)
    end
    it 'sets settings for access and secret' do
      expect(Skyed::AWS.region)
        .to eq(another_region)
    end
  end
end

describe 'Skyed::AWS.set_credentials' do
  let(:access) { 'AKIAAAAAA' }
  let(:secret) { 'zMLdko39fj' }
  before(:each) do
    expect(Skyed::AWS)
      .to receive(:valid_credential?)
      .with('AWS_ACCESS_KEY')
      .and_return(true)
    expect(Skyed::AWS)
      .to receive(:valid_credential?)
      .with('AWS_SECRET_KEY')
      .and_return(true)
    expect(Skyed::AWS)
      .to receive(:confirm_credentials?)
      .with(access, secret)
      .and_return(true)
  end
  it 'sets settings for access and secret' do
    Skyed::AWS.set_credentials(access, secret)
    expect(Skyed::Settings.access_key)
      .to eq(access)
    expect(Skyed::Settings.secret_key)
      .to eq(secret)
  end
end

describe 'Skyed::AWS.valid_credential?' do
  let(:varname) { 'AWS_ACCESS_KEY' }
  context 'when the environment variable is nil' do
    before do
      expect(ENV)
        .to receive(:[])
        .twice
        .with(varname)
        .and_return(nil)
    end
    it 'returns false' do
      expect(Skyed::AWS.valid_credential?(varname))
        .to eq(false)
    end
  end
  context 'when the environment variable is empty' do
    before do
      expect(ENV)
        .to receive(:[])
        .with(varname)
        .and_return('')
    end
    it 'returns false' do
      expect(Skyed::AWS.valid_credential?(varname))
        .to eq(false)
    end
  end
  context 'when the environment variable is not null and is not empty' do
    before do
      expect(ENV)
        .to receive(:[])
        .twice
        .with(varname)
        .and_return('AKIAKKK')
    end
    it 'returns true' do
      expect(Skyed::AWS.valid_credential?(varname))
        .to eq(true)
    end
  end
end

describe 'Skyed::AWS.confirm_credentials?' do
  let(:iam)        { double('Aws::IAM::Client') }
  let(:access_key) { 'AKIAASASASASASAS' }
  let(:secret_key) { 'zMdiopqw0923pojsdfklhjdesa09213' }
  before(:each) do
    expect(Skyed::AWS::IAM)
      .to receive(:login)
      .and_return(iam)
  end
  context 'when credentials are correct' do
    before do
      expect(iam)
        .to receive(:get_account_summary)
        .and_return(summary_map: {})
    end
    it 'returns true' do
      expect(Skyed::AWS.confirm_credentials?(access_key, secret_key))
        .to eq(true)
    end
  end
  context 'when credentials are incorrect' do
    before do
      expect(iam)
        .to receive(:get_account_summary)
        .and_raise(Aws::IAM::Errors::InvalidClientTokenId.new(nil, nil))
    end
    it 'returns true' do
      expect(Skyed::AWS.confirm_credentials?(access_key, secret_key))
        .to eq(false)
    end
  end
end

describe 'Skyed::AWS::RDS.create_instance_from_snapshot' do
  let(:rds)           { double('AWS::RDS::Client') }
  let(:options) do
    {
      rds: true,
      size: 100,
      type: 'm1.large',
      user: 'root',
      pass: 'my_password',
      db_security_group_name: 'rds-launch-wizard',
      db_parameters_group_name: 'my_db_params',
      wait_interval: 0
    }
  end
  let(:instance_name) { 'my-rds' }
  let(:snapshot)      { 'rds:instance-2015-06-10-00-06' }
  let(:endpoint)      { 'my-rds.c7werpdeshqu.us-east-1.rds.amazonaws.com' }
  let(:port)          { 5432 }
  let(:response) do
    {
      endpoint: {
        address: endpoint,
        port: port
      }
    }
  end
  let(:status_available) do
    {
      db_instance_identifier: instance_name,
      db_instance_status: 'available',
      endpoint: {
        address: endpoint,
        port: port
      }
    }
  end
  let(:generated_args) do
    {
      db_instance_identifier: instance_name,
      db_snapshot_identifier: snapshot
    }
  end
  before(:each) do
    expect(Skyed::AWS::RDS)
      .to receive(:login)
      .and_return(rds)
    expect(rds)
      .to receive(:restore_db_instance_from_db_snapshot)
      .with(generated_args)
      .and_return(db_instance: response)
    expect(Skyed::AWS::RDS)
      .to receive(:wait_for_instance)
      .with(instance_name, 'available', 0, rds)
      .and_return(status_available)
  end
  it 'creates the new instance from snapshot' do
    expect(Skyed::AWS::RDS.create_instance_from_snapshot(
      instance_name,
      snapshot,
      options))
      .to eq("#{endpoint}:#{port}")
  end
end

describe 'Skyed::AWS::RDS.list_snapshots' do
  let(:rds)       { double('AWS::RDS::Client') }
  let(:options) do
    {
      rds: true
    }
  end
  let(:response)  { double('Aws::RDS::Types::DBSnapshotMessage') }
  let(:snapshot1) { double('Aws::RDS::Types::DBSnapshot') }
  let(:snapshot2) { double('Aws::RDS::Types::DBSnapshot') }
  let(:snapshots) { [snapshot1, snapshot2] }
  before(:each) do
    expect(Skyed::AWS::RDS)
      .to receive(:login)
      .and_return(rds)
    expect(response)
      .to receive(:db_snapshots)
      .and_return(snapshots)
  end
  context 'when no specific db instance was specified' do
    before(:each) do
      expect(rds)
        .to receive(:describe_db_snapshots)
        .and_return(response)
    end
    it 'lists all snapshots' do
      expect(Skyed::AWS::RDS.list_snapshots(options, nil))
        .to eq(snapshots)
    end
  end
  context 'when specific db instance was specified' do
    let(:args) { ['my-rds'] }
    let(:snapshots) { [snapshot1] }
    before(:each) do
      expect(rds)
        .to receive(:describe_db_snapshots)
        .with(db_instance_identifier: 'my-rds')
        .and_return(response)
    end
    it 'lists snapshots taken from the specified db instance' do
      expect(Skyed::AWS::RDS.list_snapshots(options, args))
        .to eq(snapshots)
    end
  end
end

describe 'Skyed::AWS::RDS.wait_for_instance' do
  let(:rds)           { double('AWS::RDS::Client') }
  let(:instance_name) { 'my-rds' }
  let(:status_pending) do
    {
      db_instance_identifier: instance_name,
      db_instance_status: 'pending'
    }
  end
  let(:status_available) do
    {
      db_instance_identifier: instance_name,
      db_instance_status: 'available'
    }
  end
  before(:each) do
    expect(rds)
      .to receive(:describe_db_instances)
      .with(db_instance_identifier: instance_name)
      .and_return(db_instances: [status_pending])
    expect(rds)
      .to receive(:describe_db_instances)
      .with(db_instance_identifier: instance_name)
      .and_return(db_instances: [status_available])
  end
  it 'waits for the status to be available' do
    Skyed::AWS::RDS.wait_for_instance(instance_name, 'available', 0, rds)
  end
end

describe 'Skyed::AWS::RDS.destroy_instance' do
  let(:rds)           { double('AWS::RDS::Client') }
  let(:instance_name) { 'my-rds' }
  let(:options) do
    {
      rds: true,
      final_snapshot_name: ''
    }
  end
  let(:generated_args) do
    {
      db_instance_identifier: instance_name,
      skip_final_snapshot: true
    }
  end
  let(:response) do
    {
      db_instance_identifier: instance_name
    }
  end
  before(:each) do
    expect(Skyed::AWS::RDS)
      .to receive(:login)
      .and_return(rds)
    expect(Skyed::AWS::RDS)
      .to receive(:generate_params)
      .with(instance_name, options)
      .and_return(generated_args)
    expect(rds)
      .to receive(:delete_db_instance)
      .with(generated_args)
      .and_return(db_instance: response)
  end
  it 'deletes the instance' do
    Skyed::AWS::RDS.destroy_instance(instance_name, options)
  end
end

describe 'Skyed::AWS::RDS.generate_params' do
  context 'when invoked for create instance' do
    let(:options) do
      {
        rds: true,
        size: 100,
        type: 'm1.large',
        user: 'root',
        password: 'my_password',
        db_security_group: 'rds-launch-wizard',
        db_parameters_group: 'my_db_params'
      }
    end
    let(:instance_name) { 'my-rds' }
    let(:generated_args) do
      {
        db_instance_identifier: instance_name,
        allocated_storage: 100,
        db_instance_class: 'db.m1.large',
        engine: 'postgres',
        master_username: 'root',
        master_user_password: 'my_password',
        db_security_groups: ['rds-launch-wizard'],
        db_parameter_group_name: 'my_db_params'
      }
    end
    it 'generates arguments for the create_db_instance' do
      expect(Skyed::AWS::RDS.generate_params(instance_name, options))
        .to eq(generated_args)
    end
  end
  context 'when invoked for delete instance' do
    context 'without final_snapshot_name' do
      let(:options) do
        {
          rds: true,
          final_snapshot_name: ''
        }
      end
      let(:instance_name) { 'my-rds' }
      let(:generated_args) do
        {
          db_instance_identifier: instance_name,
          skip_final_snapshot: true
        }
      end
      it 'generates arguments for the delete_db_instance' do
        expect(Skyed::AWS::RDS.generate_params(instance_name, options))
          .to eq(generated_args)
      end
    end
    context 'with final_snapshot_name' do
      let(:options) do
        {
          rds: true,
          final_snapshot_name: 'final_snap'
        }
      end
      let(:instance_name) { 'my-rds' }
      let(:generated_args) do
        {
          db_instance_identifier: instance_name,
          skip_final_snapshot: false,
          final_snapshot_name: 'final_snap'
        }
      end
      it 'generates arguments for the delete_db_instance' do
        expect(Skyed::AWS::RDS.generate_params(instance_name, options))
          .to eq(generated_args)
      end
    end
  end
end

describe 'Skyed::AWS::RDS.create_instance' do
  let(:rds)           { double('AWS::RDS::Client') }
  let(:options) do
    {
      rds: true,
      size: 100,
      type: 'm1.large',
      user: 'root',
      pass: 'my_password',
      db_security_group_name: 'rds-launch-wizard',
      db_parameters_group_name: 'my_db_params'
    }
  end
  let(:instance_name) { 'my-rds' }
  let(:endpoint)      { 'my-rds.c7werpdeshqu.us-east-1.rds.amazonaws.com' }
  let(:port)          { 5432 }
  let(:response) do
    {
      endpoint: {
        address: endpoint,
        port: port
      }
    }
  end
  let(:status_available) do
    {
      db_instance_identifier: instance_name,
      db_instance_status: 'available',
      endpoint: {
        address: endpoint,
        port: port
      }
    }
  end
  let(:generated_args) do
    {
      db_instance_identifier: instance_name,
      allocated_storage: 100,
      db_instance_class: 'db.m1.large',
      engine: 'postgres',
      master_username: 'root',
      master_user_password: 'my_password',
      db_security_groups: ['rds-launch-wizard'],
      db_parameter_group_name: 'my_db_params'
    }
  end
  before(:each) do
    expect(Skyed::AWS::RDS)
      .to receive(:login)
      .and_return(rds)
    expect(Skyed::AWS::RDS)
      .to receive(:generate_params)
      .with(instance_name, options)
      .and_return(generated_args)
    expect(rds)
      .to receive(:create_db_instance)
      .with(generated_args)
      .and_return(db_instance: response)
    expect(Skyed::AWS::RDS)
      .to receive(:wait_for_instance)
      .with(instance_name, 'available', 0, rds)
      .and_return(status_available)
  end
  it 'creates the new instance' do
    expect(Skyed::AWS::RDS.create_instance(instance_name, options))
      .to eq("#{endpoint}:#{port}")
  end
end

describe 'Skyed::AWS::RDS.login' do
  let(:rds)        { double('AWS::RDS::Client') }
  let(:access_key) { 'AKIAASASASASASAS' }
  let(:secret_key) { 'zMdiopqw0923pojsdfklhjdesa09213' }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:access_key)
      .and_return(access_key)
    expect(Skyed::Settings)
      .to receive(:secret_key)
      .and_return(secret_key)
    expect(Aws::RDS::Client)
      .to receive(:new)
      .with(
        access_key_id: access_key,
        secret_access_key: secret_key,
        region: 'us-east-1')
      .and_return(rds)
  end
  it 'logins and returns the RDS client' do
    expect(Skyed::AWS::RDS.login)
      .to eq(rds)
  end
end

describe 'Skyed::AWS::OpsWorks.stop_instance' do
  let(:opsworks)    { double('Aws::OpsWorks::Client') }
  let(:hostname)    { 'test1' }
  let(:stack_id)    { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:instance_id) { '12345678-1234-4321-5678-210987654321' }
  let(:instance1) do
    Instance.new(instance_id, hostname, stack_id, nil, 'online')
  end
  before(:each) do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:login)
      .and_return(opsworks)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:instance_by_name)
      .with(hostname, stack_id, opsworks)
      .and_return(instance1)
    expect(opsworks)
      .to receive(:stop_instance)
      .with(instance_id: instance_id)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:wait_for_instance_id)
      .with(instance_id, 'stopped', opsworks)
  end
  it 'stops the new instance' do
    Skyed::AWS::OpsWorks.stop_instance(
      stack_id,
      hostname)
  end
end

describe 'Skyed::AWS::OpsWorks.create_instance' do
  let(:opsworks)      { double('Aws::OpsWorks::Client') }
  let(:instance_type) { 'm1.large' }
  let(:hostname)      { 'test1' }
  let(:stack_id)      { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:layer_id)      { '56a3041e-e682-e5b4-8976-a4b749c6043c' }
  let(:instance_id)   { '12345678-1234-4321-5678-210987654321' }
  let(:instance_online) do
    Instance.new(
      instance_id,
      hostname,
      stack_id,
      nil,
      'online'
    )
  end
  before(:each) do
    expect(opsworks)
      .to receive(:create_instance)
      .with(
        stack_id: stack_id,
        layer_ids: [layer_id],
        instance_type: instance_type)
      .and_return(instance_online)
    expect(opsworks)
      .to receive(:start_instance)
      .with(instance_id: instance_id)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:wait_for_instance_id)
      .with(instance_id, 'online', opsworks)
  end
  it 'creates the new instance' do
    Skyed::AWS::OpsWorks.create_instance(
      stack_id,
      layer_id,
      instance_type,
      opsworks)
  end
end

describe 'Skyed::AWS::OpsWorks.wait_for_instance_id' do
  let(:opsworks)    { double('Aws::OpsWorks::Client') }
  let(:instance_id) { '87654321-4321-4321-4321-210987654321' }
  let(:stack_id)    { '12345678-1234-1234-1234-123456789012' }
  let(:result1)     { double('Aws::OpsWorks::Types::DescribeInstancesResult') }
  let(:result2)     { double('Aws::OpsWorks::Types::DescribeInstancesResult') }
  let(:instances1)  { [instance1_booting] }
  let(:instances2)  { [instance1_online] }
  let(:instance1_booting) do
    Instance.new(
      '87654321-4321-4321-4321-210987654321',
      'test1',
      stack_id,
      nil,
      'booting')
  end
  let(:instance1_online) do
    Instance.new(
      '87654321-4321-4321-4321-210987654321',
      'test1',
      stack_id,
      nil,
      'online')
  end
  context 'when it is booting and waiting for online' do
    before(:each) do
      expect(result1)
        .to receive(:instances)
        .and_return(instances1)
      expect(result2)
        .to receive(:instances)
        .and_return(instances2)
      expect(opsworks)
        .to receive(:describe_instances)
        .with(instance_ids: [instance_id])
        .once
        .and_return(result1)
      expect(opsworks)
        .to receive(:describe_instances)
        .with(instance_ids: [instance_id])
        .once
        .and_return(result2)
    end
    it 'waits for the instance to be in the correct status' do
      Skyed::AWS::OpsWorks.wait_for_instance_id(
        instance_id,
        'online',
        opsworks)
    end
  end
end

describe 'Skyed::AWS::OpsWorks.deregister_insatance' do
  let(:opsworks)    { double('Aws::OpsWorks::Client') }
  let(:hostname)    { 'test-ifosch' }
  let(:stack_id)    { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:instance_id) { '12345678-1234-4321-5678-210987654321' }
  let(:instance_online) do
    Instance.new(
      instance_id,
      hostname,
      stack_id,
      nil,
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
    expect(Skyed::AWS::OpsWorks)
      .to receive(:wait_for_instance)
      .with(hostname, stack_id, 'terminated', opsworks)
  end
  it 'deregisters the vagrant machine' do
    Skyed::AWS::OpsWorks.deregister_instance(hostname, opsworks)
  end
end

describe 'Skyed::AWS::OpsWorks.delete_user' do
  let(:opsworks)  { double('Aws::OpsWorks::Client') }
  let(:stack_id)  { '12345678-1234-1234-1234-123456789012' }
  let(:stack_name) { 'stack' }
  let(:layer_id)  { '87654321-4321-4321-4321-210987654321' }
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
  before(:each) do
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
  it 'deletes the current OpsWorks user' do
    Skyed::AWS::OpsWorks.delete_user(opsworks)
  end
end

describe 'Skyed::AWS::OpsWorks.wait_for_instance' do
  let(:opsworks)  { double('Aws::OpsWorks::Client') }
  let(:instance_name) { 'test-user1' }
  let(:stack_id)      { '12345678-1234-1234-1234-123456789012' }
  let(:instances)     { { instances: [instance2, instance1] } }
  let(:instance1_booting) do
    Instance.new(
      '87654321-4321-4321-4321-210987654321',
      instance_name,
      stack_id,
      nil,
      'booting')
  end
  let(:instance1_online) do
    Instance.new(
      '87654321-4321-4321-4321-210987654321',
      instance_name,
      stack_id,
      nil,
      'online')
  end
  context 'when it is booting and waiting for online' do
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:instance_by_name)
        .with(instance_name, stack_id, opsworks)
        .once
        .and_return(instance1_booting)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:instance_by_name)
        .with(instance_name, stack_id, opsworks)
        .once
        .and_return(instance1_online)
    end
    it 'waits for the instance to be in the correct status' do
      Skyed::AWS::OpsWorks.wait_for_instance(
        instance_name,
        stack_id,
        'online',
        opsworks)
    end
  end
  context 'when the instance gets deregistered it is nil' do
    let(:instance1_deregistering) do
      Instance.new(
        '87654321-4321-4321-4321-210987654321',
        instance_name,
        stack_id,
        nil,
        'stopping')
    end
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:instance_by_name)
        .with(instance_name, stack_id, opsworks)
        .once
        .and_return(instance1_booting)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:instance_by_name)
        .with(instance_name, stack_id, opsworks)
        .once
        .and_return(nil)
    end
    it 'waits for the instance to be in the correct status' do
      Skyed::AWS::OpsWorks.wait_for_instance(
        instance_name,
        stack_id,
        'deregistered',
        opsworks)
    end
  end
end

describe 'Skyed::AWS::OpsWorks.stack' do
  let(:opsworks) { double('Aws::OpsWorks::Client') }
  let(:stack1)   { { stack_id: '1', name: 'My First Stack' } }
  let(:stack2)   { { stack_id: '2', name: 'My Second Stack' } }
  let(:stacks)   { [stack1, stack2] }
  before do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:stacks)
      .at_least(1)
      .with(opsworks)
      .and_return(stacks)
  end
  it 'returns the stack with the specified id or name' do
    expect(Skyed::AWS::OpsWorks.stack('1', opsworks))
      .to eq(stack1)
    expect(Skyed::AWS::OpsWorks.stack('My First Stack', opsworks))
      .to eq(stack1)
    expect(Skyed::AWS::OpsWorks.stack('2', opsworks))
      .to eq(stack2)
    expect(Skyed::AWS::OpsWorks.stack('My Second Stack', opsworks))
      .to eq(stack2)
    expect(Skyed::AWS::OpsWorks.stack('3', opsworks))
      .to eq(nil)
    expect(Skyed::AWS::OpsWorks.stack('Non-existant Stack', opsworks))
      .to eq(nil)
  end
end

describe 'Skyed::AWS::OpsWorks.layer' do
  let(:opsworks) { double('Aws::OpsWorks::Client') }
  let(:layer1)   { { stack_id: '1', layer_id: '1', name: 'My First Layer' } }
  let(:layer2)   { { stack_id: '2', layer_id: '2', name: 'My Second Layer' } }
  let(:layers)   { [layer1, layer2] }
  before do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:layers)
      .at_least(1)
      .with(opsworks)
      .and_return(layers)
  end
  it 'returns the layer with the specified id or name' do
    expect(Skyed::AWS::OpsWorks.layer('1', opsworks))
      .to eq(layer1)
    expect(Skyed::AWS::OpsWorks.layer('My First Layer', opsworks))
      .to eq(layer1)
    expect(Skyed::AWS::OpsWorks.layer('2', opsworks))
      .to eq(layer2)
    expect(Skyed::AWS::OpsWorks.layer('My Second Layer', opsworks))
      .to eq(layer2)
    expect(Skyed::AWS::OpsWorks.layer('3', opsworks))
      .to eq(nil)
    expect(Skyed::AWS::OpsWorks.layer('Non-existant Layer', opsworks))
      .to eq(nil)
  end
end

describe 'Skyed::AWS::OpsWorks.deploy' do
  context 'for update_custom_cookbooks' do
    let(:stack_id)  { '93859374-2382-9874-4592-239287433254' }
    let(:command)   { { name: 'update_custom_cookbooks' } }
    let(:opsworks)  { double('Aws::OpsWorks::Client') }
    let(:instances) { ['65482357-4896-9876-9871-354687513596'] }
    let(:deploy_id) { { deployment_id: '3859374-2382-9874-4592-239287433254' } }
    let(:wait)      { 0 }
    let(:deploy_params) do
      {
        stack_id: stack_id,
        command: command,
        instance_ids: instances
      }
    end
    before do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:generate_deploy_params)
        .with(stack_id, command, instance_ids: instances)
        .and_return(deploy_params)
      expect(opsworks)
        .to receive(:create_deployment)
        .with(deploy_params)
        .and_return(deploy_id)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:wait_for_deploy)
        .with(deploy_id, opsworks, wait)
        .and_return(['successful'])
    end
    it 'run deployment' do
      expect(Skyed::AWS::OpsWorks.deploy(
        stack_id: stack_id,
        command: command,
        instance_ids: instances,
        client: opsworks,
        wait_interval: wait))
        .to eq(['successful'])
    end
  end
  context 'for execute_recipes' do
    let(:stack_id)  { '93859374-2382-9874-4592-239287433254' }
    let(:recipe1)   { 'recipe1' }
    let(:cmd_args)  { { recipes: [recipe1] } }
    let(:command)   { { name: 'execute_recipes', args: cmd_args } }
    let(:opsworks)  { double('Aws::OpsWorks::Client') }
    let(:instances) { ['65482357-4896-9876-9871-354687513596'] }
    let(:deploy_id) { { deployment_id: '3859374-2382-9874-4592-239287433254' } }
    let(:wait)      { 0 }
    let(:deploy_params) do
      {
        stack_id: stack_id,
        command: command,
        instance_ids: instances
      }
    end
    before(:each) do
      expect(opsworks)
        .to receive(:create_deployment)
        .with(deploy_params)
        .and_return(deploy_id)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:wait_for_deploy)
        .with(deploy_id, opsworks, wait)
        .and_return(['successful'])
    end
    context 'without custom_json' do
      before(:each) do
        expect(Skyed::AWS::OpsWorks)
          .to receive(:generate_deploy_params)
          .with(stack_id, command, instance_ids: instances)
          .and_return(deploy_params)
      end
      it 'run deployment' do
        expect(Skyed::AWS::OpsWorks.deploy(
          stack_id: stack_id,
          command: command,
          instance_ids: instances,
          client: opsworks,
          wait_interval: wait))
          .to eq(['successful'])
      end
    end
    context 'with custom_json' do
      let(:custom_json) { { key: 'value' } }
      let(:deploy_params) do
        {
          stack_id: stack_id,
          command: command,
          instance_ids: instances,
          custom_json: custom_json
        }
      end
      before(:each) do
        expect(Skyed::AWS::OpsWorks)
          .to receive(:generate_deploy_params)
          .with(
            stack_id,
            command,
            instance_ids: instances,
            custom_json: custom_json)
          .and_return(deploy_params)
      end
      it 'run deployment' do
        expect(Skyed::AWS::OpsWorks.deploy(
          stack_id: stack_id,
          command: command,
          instance_ids: instances,
          custom_json: custom_json,
          client: opsworks,
          wait_interval: wait))
          .to eq(['successful'])
      end
    end
  end
end

describe 'Skyed::AWS::OpsWorks.layer_by_id' do
  let(:opsworks) { double('Aws::OpsWorks::Client') }
  let(:layer1)   { { stack_id: '1', layer_id: '1', name: 'My First Layer' } }
  let(:layer2)   { { stack_id: '2', layer_id: '2', name: 'My Second Layer' } }
  let(:layers)   { [layer1, layer2] }
  before do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:layers)
      .at_least(1)
      .with(opsworks)
      .and_return(layers)
  end
  it 'returns the layer with the specified id' do
    expect(Skyed::AWS::OpsWorks.layer_by_id('1', opsworks))
      .to eq(layer1)
    expect(Skyed::AWS::OpsWorks.layer_by_id('2', opsworks))
      .to eq(layer2)
    expect(Skyed::AWS::OpsWorks.layer_by_id('3', opsworks))
      .to eq(nil)
  end
end

describe 'Skyed::AWS::OpsWorks.layer_by_name' do
  let(:opsworks) { double('Aws::OpsWorks::Client') }
  let(:layer1)   { { stack_id: '1', layer_id: '1', name: 'My First Layer' } }
  let(:layer2)   { { stack_id: '2', layer_id: '2', name: 'My Second Layer' } }
  let(:layers)   { [layer1, layer2] }
  before do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:layers)
      .at_least(1)
      .with(opsworks)
      .and_return(layers)
  end
  it 'returns the layer with the specified name' do
    expect(Skyed::AWS::OpsWorks.layer_by_name('My First Layer', opsworks))
      .to eq(layer1)
    expect(Skyed::AWS::OpsWorks.layer_by_name('My Second Layer', opsworks))
      .to eq(layer2)
    expect(Skyed::AWS::OpsWorks.layer_by_name('Non-existant Layer', opsworks))
      .to eq(nil)
  end
end

describe 'Skyed::AWS::OpsWorks.layers' do
  let(:opsworks) { double('Aws::OpsWorks::Client') }
  let(:layer1)   { { stack_id: '1', layer_id: '1', name: 'My First Layer' } }
  let(:layer2)   { { stack_id: '2', layer_id: '2', name: 'My Second Layer' } }
  let(:layers)   { { layers: [layer1] } }
  before do
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .and_return('1')
    expect(opsworks)
      .to receive(:describe_layers)
      .with(stack_id: '1')
      .and_return(layers)
  end
  it 'returns a list of all layers' do
    expect(Skyed::AWS::OpsWorks.layers(opsworks))
      .to eq([layer1])
  end
end

describe 'Skyed::AWS::OpsWorks.stack_by_id' do
  let(:opsworks) { double('Aws::OpsWorks::Client') }
  let(:stack1)   { { stack_id: '1', name: 'My First Stack' } }
  let(:stack2)   { { stack_id: '2', name: 'My Second Stack' } }
  let(:stacks)   { [stack1, stack2] }
  before do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:stacks)
      .at_least(1)
      .with(opsworks)
      .and_return(stacks)
  end
  it 'returns the stack with the specified id' do
    expect(Skyed::AWS::OpsWorks.stack_by_id('1', opsworks))
      .to eq(stack1)
    expect(Skyed::AWS::OpsWorks.stack_by_id('2', opsworks))
      .to eq(stack2)
    expect(Skyed::AWS::OpsWorks.stack_by_id('3', opsworks))
      .to eq(nil)
  end
end

describe 'Skyed::AWS::OpsWorks.running_instances' do
  let(:opsworks)      { double('Aws::OpsWorks::Client') }
  let(:stack_id)      { '654654-654654-654654-654654' }
  let(:layer_id)      { '456456-456456-456456-456456' }
  let(:instances)     { { instances: [instance2, instance1] } }
  let(:instance1) do
    Instance.new(
      '9876-9876-9876-9876',
      'test',
      stack_id,
      [layer_id],
      'online'
    )
  end
  let(:instance2) do
    Instance.new(
      '9876-9876-9876-9877',
      'test-user2',
      stack_id,
      [layer_id],
      'stopped'
    )
  end
  before do
    expect(opsworks)
      .to receive(:describe_instances)
      .with(layer_id: layer_id)
      .at_least(1)
      .and_return(instances)
  end
  it 'returns list of running intances' do
    expect(Skyed::AWS::OpsWorks.running_instances(
      { layer_id: layer_id }, opsworks))
      .to eq([instance1.instance_id])
  end
end

describe 'Skyed::AWS::OpsWorks.instance_by_name' do
  let(:opsworks)      { double('Aws::OpsWorks::Client') }
  let(:instance_name) { 'test-user1' }
  let(:stack_id)      { '654654-654654-654654-654654' }
  let(:instances)     { { instances: [instance2, instance1] } }
  let(:instance1) do
    Instance.new('9876-9876-9876-9876', instance_name, stack_id, nil, 'online')
  end
  let(:instance2) do
    Instance.new('9876-9876-9876-9877', 'test-user2', stack_id, nil, 'online')
  end
  before do
    expect(opsworks)
      .to receive(:describe_instances)
      .with(stack_id: stack_id)
      .at_least(1)
      .and_return(instances)
  end
  it 'returns the instance with the specified name' do
    expect(Skyed::AWS::OpsWorks.instance_by_name(
      instance_name, stack_id, opsworks))
      .to eq(instance1)
    expect(Skyed::AWS::OpsWorks.instance_by_name(
      'test-user3', stack_id, opsworks))
      .to eq(nil)
  end
end

describe 'Skyed::AWS::OpsWorks.wait_for_deploy' do
  let(:opsworks)  { double('Aws::OpsWorks::Client') }
  let(:deploy_id) { '57225c7f-1c06-4fd2-98d5-f39d9a484d62' }
  let(:deploy)    { { deployment_id: deploy_id } }
  before(:each) do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:deploy_status)
      .with(deploy, opsworks)
      .once
      .and_return(['running'])
    expect(Skyed::AWS::OpsWorks)
      .to receive(:deploy_status)
      .with(deploy, opsworks)
      .and_return(['successful'])
  end
  it 'returns the deploy status' do
    expect(Skyed::AWS::OpsWorks.wait_for_deploy deploy, opsworks)
      .to eq(['successful'])
  end
end

describe 'Skyed::AWS::OpsWorks.deploy_status' do
  let(:opsworks)  { double('Aws::OpsWorks::Client') }
  let(:deploy_id) { '57225c7f-1c06-4fd2-98d5-f39d9a484d62' }
  let(:deploy)    { { deployment_id: deploy_id } }
  before(:each) do
    expect(opsworks)
      .to receive(:describe_deployments)
      .with(deployment_ids: [deploy_id])
      .and_return(deployments: [{ status: 'running' }])
  end
  it 'returns the deploy status' do
    expect(Skyed::AWS::OpsWorks.deploy_status deploy, opsworks)
      .to eq(['running'])
  end
end

describe 'Skyed::AWS::OpsWorks.generate_deploy_params' do
  context 'for update_custom_cookbooks command' do
    let(:stack_id) { '57225c7f-1c06-4fd2-98d5-f39d9a484d62' }
    let(:command) { { name: 'update_custom_cookbooks' } }
    it 'returns the create_deployment arguments' do
      expect(Skyed::AWS::OpsWorks.generate_deploy_params stack_id, command)
        .to eq(stack_id: stack_id, command: command)
    end
    context 'when including instance IDs list' do
      let(:instances) { ['i-23456', 'i-65432'] }
      it 'returns the create_deployment arguments' do
        expect(Skyed::AWS::OpsWorks.generate_deploy_params(
          stack_id,
          command,
          instance_ids: instances))
          .to eq(stack_id: stack_id, command: command, instance_ids: instances)
      end
    end
  end
end

describe 'Skyed::AWS::OpsWorks.generate_command_params' do
  context 'for update_custom_cookbooks command' do
    let(:options) { { name: 'update_custom_cookbooks' } }
    it 'returns the update_custom_cookbooks params' do
      expect(Skyed::AWS::OpsWorks.generate_command_params options)
        .to eq(options)
    end
  end
  context 'for execute_recipes command' do
    let(:recipes) { ['cookbook::recipe'] }
    let(:options) do
      {
        name: 'execute_recipes',
        recipes: recipes
      }
    end
    let(:response) do
      {
        name: 'execute_recipes',
        args: { recipes: recipes }
      }
    end
    it 'returns the execute_recipes params' do
      expect(Skyed::AWS::OpsWorks.generate_command_params options)
        .to eq(response)
    end
  end
end

describe 'Skyed::AWS::OpsWorks.create_layer' do
  let(:opsworks)       { double('Aws::OpsWorks::Client') }
  let(:ow_layer_response) { double('Core::Response') }
  let(:stack_id)          { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:layer_id)          { 'e1403a56-286e-4b5e-6798-c3406c947b4b' }
  let(:layer_data)        { { layer_id: layer_id } }
  let(:layer_params) do
    {
      stack_id: stack_id,
      type: 'asdasdas',
      name: 'test-user',
      shortname: 'test-user',
      custom_security_group_ids: ['sg-f1cc2498']
    }
  end
  before do
    expect(opsworks)
      .to receive(:create_layer)
      .with(layer_params)
      .and_return(ow_layer_response)
    expect(ow_layer_response)
      .to receive(:data)
      .and_return(layer_data)
  end
  it 'creates the layer and sets the id' do
    Skyed::AWS::OpsWorks.create_layer(layer_params, opsworks)
    expect(Skyed::Settings.layer_id)
      .to eq(layer_id)
  end
end

describe 'Skyed::AWS::OpsWorks.create_stack' do
  let(:opsworks)       { double('Aws::OpsWorks::Client') }
  let(:stack_params) do
    {
      name: 'user',
      region: 'us-east-1',
      service_role_arn: 'asdasdas',
      default_instance_profile_arn: 'asdasasd',
      default_os: 'Ubuntu 12.04 LTS',
      configuration_manager: {
        name: 'Chef',
        version: '11.10'
      },
      use_custom_cookbooks: true,
      default_ssh_key_name: 'key-pair',
      custom_cookbooks_source: {
        url: 'git@github.com:user/repo',
        revision: 'devel-1',
        ssh_key: 'ASDDFSASDFASDF',
        type: 'git'
      },
      use_opsworks_security_groups: false
    }
  end
  let(:ow_stack_response) { double('Core::Response') }
  let(:stack_id)          { 'e1403a56-286e-4b5e-6798-c3406c947b4a' }
  let(:stack_data)        { { stack_id: stack_id } }
  before do
    expect(opsworks)
      .to receive(:create_stack)
      .with(stack_params)
      .and_return(ow_stack_response)
    expect(ow_stack_response)
      .to receive(:data)
      .and_return(stack_data)
  end
  it 'creates the stack and sets the id' do
    Skyed::AWS::OpsWorks.create_stack(stack_params, opsworks)
    expect(Skyed::Settings.stack_id)
      .to eq(stack_id)
  end
end

describe 'Skyed::AWS::OpsWorks.delete_stack' do
  let(:opsworks)       { double('Aws::OpsWorks::Client') }
  let(:stack1)         { { stack_id: 1, name: 'My First Stack' } }
  context 'when there is no instances in the stack' do
    before do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:count_instances)
        .with('My First Stack', opsworks)
        .and_return(0)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:stack_by_name)
        .with('My First Stack', opsworks)
        .and_return(stack1)
      expect(opsworks)
        .to receive(:delete_stack)
        .with(stack_id: 1)
    end
    it 'deletes the stack' do
      Skyed::AWS::OpsWorks.delete_stack('My First Stack', opsworks)
    end
  end
  context 'when there is any instance in the stack' do
    before do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:count_instances)
        .with('My Used Stack', opsworks)
        .and_return(5)
    end
    it 'fails to delete the stack' do
      expect { Skyed::AWS::OpsWorks.delete_stack('My Used Stack', opsworks) }
        .to raise_error
    end
  end
end

describe 'Skyed::AWS::OpsWorks.count_instances' do
  let(:opsworks)       { double('Aws::OpsWorks::Client') }
  let(:instances_count0) do
    {
      assigning: nil,
      booting: nil,
      connection_lost: nil,
      deregistering: nil,
      online: nil,
      pending: nil,
      rebooting: nil,
      registered: nil,
      registering: nil,
      requested: nil,
      running_setup: nil,
      setup_failed: nil,
      shutting_down: nil,
      start_failed: nil,
      stopped: nil,
      stopping: nil,
      terminated: nil,
      terminating: nil,
      unassigning: nil
    }
  end
  let(:instances_count1) do
    {
      assigning: 0,
      booting: 0,
      connection_lost: 0,
      deregistering: 0,
      online: 1,
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
  let(:stack1_summary) do
    {
      stack_id: 1,
      name: 'My First Stack',
      instances_count: instances_count1
    }
  end
  let(:stack2_summary) do
    {
      stack_id: 2,
      name: 'My Empty Stack',
      instances_count: instances_count0
    }
  end
  before do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:stack_summary_by_name)
      .with('My First Stack', opsworks)
      .and_return(stack1_summary)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:stack_summary_by_name)
      .with('My Empty Stack', opsworks)
      .and_return(stack2_summary)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:stack_summary_by_name)
      .with('Non-existant Stack', opsworks)
      .and_return(nil)
  end
  it 'returns the instances count in the stack with the specified name' do
    expect(Skyed::AWS::OpsWorks.count_instances('My First Stack', opsworks))
      .to eq(1)
    expect(Skyed::AWS::OpsWorks.count_instances('My Empty Stack', opsworks))
      .to eq(0)
    expect(Skyed::AWS::OpsWorks.count_instances('Non-existant Stack', opsworks))
      .to eq(nil)
  end
end

describe 'Skyed::AWS::OpsWorks.stack_summary_by_name' do
  let(:opsworks)       { double('Aws::OpsWorks::Client') }
  let(:stack1)         { { stack_id: 1, name: 'My First Stack' } }
  let(:stack1_summary) { { stack_id: 1, name: 'My First Stack' } }
  let(:stack1_summary_response) do
    {
      stack_summary: stack1_summary
    }
  end
  context 'when the stack exists' do
    before do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:stack_by_name)
        .with('My First Stack', opsworks)
        .and_return(stack1)
      expect(opsworks)
        .to receive(:describe_stack_summary)
        .with(stack_id: 1)
        .and_return(stack1_summary_response)
    end
    it 'returns the stack summary for the stack with the specified name' do
      expect(Skyed::AWS::OpsWorks
               .stack_summary_by_name('My First Stack', opsworks))
        .to eq(stack1_summary)
    end
  end
  context 'when the stack does not exist' do
    before do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:stack_by_name)
        .with('Non-existant Stack', opsworks)
        .and_return(nil)
    end
    it 'returns nil' do
      expect(Skyed::AWS::OpsWorks
               .stack_summary_by_name('Non-existant Stack', opsworks))
        .to eq(nil)
    end
  end
end

describe 'Skyed::AWS::OpsWorks.stack_by_name' do
  let(:opsworks) { double('Aws::OpsWorks::Client') }
  let(:stack1)   { { stack_id: 1, name: 'My First Stack' } }
  let(:stack2)   { { stack_id: 2, name: 'My Second Stack' } }
  let(:stacks)   { [stack1, stack2] }
  before do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:stacks)
      .at_least(1)
      .with(opsworks)
      .and_return(stacks)
  end
  it 'returns the stack with the specified name' do
    expect(Skyed::AWS::OpsWorks.stack_by_name('My First Stack', opsworks))
      .to eq(stack1)
    expect(Skyed::AWS::OpsWorks.stack_by_name('My Second Stack', opsworks))
      .to eq(stack2)
    expect(Skyed::AWS::OpsWorks.stack_by_name('Non-existant Stack', opsworks))
      .to eq(nil)
  end
end

describe 'Skyed::AWS::OpsWorks.stacks' do
  let(:opsworks) { double('Aws::OpsWorks::Client') }
  let(:stack1)   { { stack_id: 1, name: 'My First Stack' } }
  let(:stack2)   { { stack_id: 2, name: 'My Second Stack' } }
  let(:stacks)   { { stacks: [stack1, stack2] } }
  before do
    expect(opsworks)
      .to receive(:describe_stacks)
      .and_return(stacks)
  end
  it 'returns a list of all stacks' do
    expect(Skyed::AWS::OpsWorks.stacks(opsworks))
      .to eq([stack1, stack2])
  end
end

describe 'Skyed::AWS::OpsWorks.custom_cookbooks_source' do
  let(:remote_url)       { 'git@github.com:user/repo' }
  let(:branch)           { 'master' }
  let(:opsworks_git_key) { '/home/user/.ssh/id_rsa' }
  let(:fd)               { double('File') }
  let(:fd_content)       { 'ssh-rsa ASDASFDFSFSDSF' }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:remote_url)
      .and_return(remote_url)
    expect(Skyed::Settings)
      .to receive(:branch)
      .and_return(branch)
    expect(Skyed::Settings)
      .to receive(:opsworks_git_key)
      .and_return(opsworks_git_key)
    expect(Skyed::Utils)
      .to receive(:read_key_file)
      .with(opsworks_git_key)
      .and_return(fd_content)
  end
  it 'returns a custom_cookbooks_source hash' do
    custom_cookbooks_source = Skyed::AWS::OpsWorks.custom_cookbooks_source({})
    expect(custom_cookbooks_source).to be_a(Hash)
    expect(custom_cookbooks_source).to have_key(:url)
    expect(custom_cookbooks_source).to have_key(:revision)
    expect(custom_cookbooks_source).to have_key(:ssh_key)
    expect(custom_cookbooks_source[:url]).to eq(remote_url)
    expect(custom_cookbooks_source[:revision]).to eq(branch)
    expect(custom_cookbooks_source[:ssh_key]).to eq(fd_content)
  end
end

describe 'Skyed::AWS::OpsWorks.generate_params' do
  let(:username)         { 'ubuntu' }
  before(:each) do
    expect(ENV)
      .to receive(:[])
      .at_least(1)
      .with('USER')
      .and_return(username)
  end
  context 'when these are for a stack' do
    let(:region)           { 'us-east-1' }
    let(:ssh_key_name)     { 'devex-keypair2' }
    let(:custom_cookbooks_source) do
      {
        remote_url: 'git@github.com:user/repo',
        branch: 'master',
        fd_content: 'ssh-rsa ASDASFDFSFSDSF'
      }
    end
    let(:service_role_ARN) do
      'arn:aws:iam::123098345737:role/aws-opsworks-service-role'
    end
    let(:instance_prof_ARN) do
      'arn:aws:iam::234098345717:instance-profile/aws-opsworks-ec2-role'
    end
    before(:each) do
      expect(Skyed::AWS)
        .to receive(:region)
        .and_return(region)
      expect(Skyed::Settings)
        .to receive(:role_arn)
        .and_return(service_role_ARN)
      expect(Skyed::Settings)
        .to receive(:profile_arn)
        .and_return(instance_prof_ARN)
      expect(Skyed::Settings)
        .to receive(:aws_key_name)
        .and_return(ssh_key_name)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:custom_cookbooks_source)
        .with(Skyed::AWS::OpsWorks::STACK[:custom_cookbooks_source])
        .and_return(custom_cookbooks_source)
    end
    it 'generates the stack parameters with current settings' do
      params = Skyed::AWS::OpsWorks.generate_params
      expect(params).to be_a(Hash)
      expect(params).to have_key(:name)
      expect(params).to have_key(:region)
      expect(params).to have_key(:service_role_arn)
      expect(params).to have_key(:default_instance_profile_arn)
      expect(params).to have_key(:default_os)
      expect(params).to have_key(:default_ssh_key_name)
      expect(params).to have_key(:custom_cookbooks_source)
      expect(params).to have_key(:custom_json)
      expect(params).to have_key(:configuration_manager)
      expect(params).to have_key(:use_custom_cookbooks)
      expect(params).to have_key(:use_opsworks_security_groups)
      expect(params[:name]).to eq(username)
      expect(params[:region]).to eq(region)
      expect(params[:service_role_arn]).to eq(service_role_ARN)
      expect(params[:default_instance_profile_arn]).to eq(instance_prof_ARN)
      expect(params[:default_ssh_key_name]).to eq(ssh_key_name)
      expect(params[:custom_cookbooks_source]).to eq(custom_cookbooks_source)
    end
    context 'and chef_version option have been issued' do
      let(:options) { { chef_version: '11.4' } }
      let(:configuration_manager) do
        {
          name: 'Chef',
          version: '11.4'
        }
      end
      it 'generates the stack parameters with current settings' do
        params = Skyed::AWS::OpsWorks.generate_params(nil, options)
        expect(params).to be_a(Hash)
        expect(params).to have_key(:name)
        expect(params).to have_key(:region)
        expect(params).to have_key(:service_role_arn)
        expect(params).to have_key(:default_instance_profile_arn)
        expect(params).to have_key(:default_os)
        expect(params).to have_key(:default_ssh_key_name)
        expect(params).to have_key(:custom_cookbooks_source)
        expect(params).to have_key(:custom_json)
        expect(params).to have_key(:configuration_manager)
        expect(params).to have_key(:use_custom_cookbooks)
        expect(params).to have_key(:use_opsworks_security_groups)
        expect(params[:name]).to eq(username)
        expect(params[:region]).to eq(region)
        expect(params[:service_role_arn]).to eq(service_role_ARN)
        expect(params[:default_instance_profile_arn]).to eq(instance_prof_ARN)
        expect(params[:default_ssh_key_name]).to eq(ssh_key_name)
        expect(params[:custom_cookbooks_source]).to eq(custom_cookbooks_source)
        expect(params[:configuration_manager]).to eq(configuration_manager)
      end
    end
    context 'and custom_json option have been issued' do
      let(:options) { { custom_json: '{ "some_key": "some_value" }' } }
      it 'generates the stack parameters with current settings' do
        params = Skyed::AWS::OpsWorks.generate_params(nil, options)
        expect(params).to be_a(Hash)
        expect(params).to have_key(:name)
        expect(params).to have_key(:region)
        expect(params).to have_key(:service_role_arn)
        expect(params).to have_key(:default_instance_profile_arn)
        expect(params).to have_key(:default_os)
        expect(params).to have_key(:default_ssh_key_name)
        expect(params).to have_key(:custom_cookbooks_source)
        expect(params).to have_key(:custom_json)
        expect(params).to have_key(:use_custom_cookbooks)
        expect(params).to have_key(:use_opsworks_security_groups)
        expect(params[:name]).to eq(username)
        expect(params[:region]).to eq(region)
        expect(params[:service_role_arn]).to eq(service_role_ARN)
        expect(params[:default_instance_profile_arn]).to eq(instance_prof_ARN)
        expect(params[:default_ssh_key_name]).to eq(ssh_key_name)
        expect(params[:custom_cookbooks_source]).to eq(custom_cookbooks_source)
        expect(params[:custom_json]).to eq(options[:custom_json])
      end
    end
  end
  context 'when these are for a layer' do
    let(:stack_id) { 1 }
    it 'generates the layer parameters with current settings' do
      params = Skyed::AWS::OpsWorks.generate_params(stack_id)
      expect(params).to be_a(Hash)
      expect(params).to have_key(:stack_id)
      expect(params).to have_key(:type)
      expect(params).to have_key(:name)
      expect(params).to have_key(:shortname)
      expect(params).to have_key(:custom_security_group_ids)
      expect(params[:stack_id]).to eq(stack_id)
      expect(params[:type]).to eq('custom')
      expect(params[:name]).to eq('test-ubuntu')
      expect(params[:shortname]).to eq('test-ubuntu')
      expect(params[:custom_security_group_ids]).to eq(['sg-f1cc2498'])
    end
  end
end

describe 'Skyed::AWS::OpsWorks.login' do
  let(:opsworks)   { double('AWS::OpsWorks::Client') }
  let(:access_key) { 'AKIAASASASASASAS' }
  let(:secret_key) { 'zMdiopqw0923pojsdfklhjdesa09213' }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:access_key)
      .and_return(access_key)
    expect(Skyed::Settings)
      .to receive(:secret_key)
      .and_return(secret_key)
    expect(Aws::OpsWorks::Client)
      .to receive(:new)
      .with(
        access_key_id: access_key,
        secret_access_key: secret_key,
        region: 'us-east-1')
      .and_return(opsworks)
  end
  it 'logins and returns the OpsWorks client' do
    expect(Skyed::AWS::OpsWorks.login)
      .to eq(opsworks)
  end
end

describe 'Skyed::AWS::OpsWorks.set_arns' do
  let(:iam)        { double('Aws::IAM::Client') }
  let(:access_key) { 'AKIAASASASASASAS' }
  let(:secret_key) { 'zMdiopqw0923pojsdfklhjdesa09213' }
  let(:service_role_ARN) do
    'arn:aws:iam::123098345737:role/aws-opsworks-service-role'
  end
  let(:instance_profile_ARN) do
    'arn:aws:iam::234098345717:instance-profile/aws-opsworks-ec2-role'
  end
  before(:each) do
    expect(Skyed::AWS::IAM)
      .to receive(:login)
      .and_return(iam)
  end
  context 'without getting predefined values' do
    before(:each) do
      expect(iam)
        .to receive(:get_role)
        .with(role_name: 'aws-opsworks-service-role')
        .and_return(role: { arn: service_role_ARN })
      expect(iam)
        .to receive(:get_instance_profile)
        .with(instance_profile_name: 'aws-opsworks-ec2-role')
        .and_return(instance_profile: { arn: instance_profile_ARN })
    end
    it 'logins and sets the OpsWorks service role and instance profile' do
      Skyed::AWS::OpsWorks.set_arns
      expect(Skyed::Settings.role_arn)
        .to eq(service_role_ARN)
      expect(Skyed::Settings.profile_arn)
        .to eq(instance_profile_ARN)
    end
  end
  context 'when getting predefined values' do
    it 'logins and sets the OpsWorks service role and instance profile' do
      Skyed::AWS::OpsWorks.set_arns(service_role_ARN, instance_profile_ARN)
      expect(Skyed::Settings.role_arn)
        .to eq(service_role_ARN)
      expect(Skyed::Settings.profile_arn)
        .to eq(instance_profile_ARN)
    end
  end
end

describe 'Skyed::AWS::IAM.remove_user_from_group' do
  let(:iam)   { double('Aws::IAM::Client') }
  let(:user)  { 'OpsWorks-stack-layer' }
  let(:group) { 'OpsWorks-stack-id' }
  before(:each) do
    expect(Skyed::AWS::IAM)
      .to receive(:login)
      .and_return(iam)
    expect(iam)
      .to receive(:remove_user_from_group)
      .with(group_name: group, user_name: user)
  end
  it 'removes user from group' do
    Skyed::AWS::IAM.remove_user_from_group user, group
  end
end

describe 'Skyed::AWS::IAM.clear_user_access_keys' do
  let(:iam)         { double('Aws::IAM::Client') }
  let(:user)        { 'OpsWorks-stack-layer' }
  let(:access_keys) { [AccessKey.new('AIKA')] }
  before(:each) do
    expect(Skyed::AWS::IAM)
      .to receive(:login)
      .and_return(iam)
    expect(iam)
      .to receive(:list_access_keys)
      .with(user_name: user)
      .and_return(access_key_metadata: access_keys)
    expect(iam)
      .to receive(:delete_access_key)
      .with(user_name: user, access_key_id: 'AIKA')
  end
  it 'clears user access keys' do
    Skyed::AWS::IAM.clear_user_access_keys user
  end
end

describe 'Skyed::AWS::IAM.clear_user_policies' do
  let(:iam)      { double('Aws::IAM::Client') }
  let(:user)     { 'OpsWorks-stack-layer' }
  let(:policies) { %w(pol1 pol2) }
  before(:each) do
    expect(Skyed::AWS::IAM)
      .to receive(:login)
      .and_return(iam)
    expect(iam)
      .to receive(:list_user_policies)
      .with(user_name: user)
      .and_return(policy_names: policies)
    expect(iam)
      .to receive(:delete_user_policy)
      .with(user_name: user, policy_name: 'pol1')
    expect(iam)
      .to receive(:delete_user_policy)
      .with(user_name: user, policy_name: 'pol2')
  end
  it 'clears user attached policies' do
    Skyed::AWS::IAM.clear_user_policies user
  end
end

describe 'Skyed::AWS::IAM.delete_user' do
  let(:iam)      { double('Aws::IAM::Client') }
  let(:user)     { 'OpsWorks-stack-layer' }
  let(:policies) { %w(pol1 pol2) }
  let(:stack_id) { '098098098098' }
  let(:group)    { 'OpsWorks-098098098098' }
  before(:each) do
    expect(Skyed::AWS::IAM)
      .to receive(:login)
      .and_return(iam)
    expect(Skyed::AWS::IAM)
      .to receive(:clear_user_policies)
      .with(user)
    expect(Skyed::AWS::IAM)
      .to receive(:clear_user_access_keys)
      .with(user)
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .at_least(1)
      .and_return(stack_id)
    expect(Skyed::AWS::IAM)
      .to receive(:remove_user_from_group)
      .with(user, group)
    expect(iam)
      .to receive(:delete_group)
      .with(group_name: group)
    expect(iam)
      .to receive(:delete_user)
      .with(user_name: user)
  end
  it 'deletes the user' do
    Skyed::AWS::IAM.delete_user user
  end
end

describe 'Skyed::AWS::IAM.login' do
  let(:iam)   { double('Aws::IAM::Client') }
  let(:access_key) { 'AKIAASASASASASAS' }
  let(:secret_key) { 'zMdiopqw0923pojsdfklhjdesa09213' }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:access_key)
      .and_return(access_key)
    expect(Skyed::Settings)
      .to receive(:secret_key)
      .and_return(secret_key)
    expect(Aws::IAM::Client)
      .to receive(:new)
      .with(
        access_key_id: access_key,
        secret_access_key: secret_key,
        region: 'us-east-1')
      .and_return(iam)
  end
  it 'logins and returns the OpsWorks client' do
    expect(Skyed::AWS::IAM.login)
      .to eq(iam)
  end
end
