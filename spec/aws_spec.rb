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
