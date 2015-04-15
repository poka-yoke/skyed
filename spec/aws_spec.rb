require 'spec_helper'
require 'skyed'

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
