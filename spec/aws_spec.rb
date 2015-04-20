require 'spec_helper'
require 'skyed'

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
