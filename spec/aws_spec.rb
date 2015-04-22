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

describe 'Skyed::AWS::OpsWorks.read_key_file' do
  let(:file_path)  { '/home/user/.ssh/id_rsa' }
  let(:fd)         { double('File') }
  let(:fd_content) { 'ssh-rsa ASDASFQASDFGRTGVW' }
  before(:each) do
    expect(File)
      .to receive(:open)
      .with(file_path, 'rb')
      .and_return(fd)
    expect(fd)
      .to receive(:read)
      .and_return(fd_content)
  end
  it 'returns the content of the key file' do
    expect(Skyed::AWS::OpsWorks.read_key_file(file_path))
      .to eq(fd_content)
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
    expect(Skyed::AWS::OpsWorks)
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
    expect(ENV)
      .to receive(:[])
      .with('USER')
      .and_return(username)
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
