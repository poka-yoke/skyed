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
    let(:instance_profile_ARN) do
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
        .and_return(instance_profile_ARN)
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
      expect(params).to have_key(:configuration_manager)
      expect(params).to have_key(:use_custom_cookbooks)
      expect(params).to have_key(:use_opsworks_security_groups)
      expect(params[:name]).to eq(username)
      expect(params[:region]).to eq(region)
      expect(params[:service_role_arn]).to eq(service_role_ARN)
      expect(params[:default_instance_profile_arn]).to eq(instance_profile_ARN)
      expect(params[:default_ssh_key_name]).to eq(ssh_key_name)
      expect(params[:custom_cookbooks_source]).to eq(custom_cookbooks_source)
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

describe 'Skyed::AWS::IAM.login' do
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
