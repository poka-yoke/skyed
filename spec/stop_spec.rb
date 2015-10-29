require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Stop.execute' do
  context 'when stopping OpsWorks instance' do
    let(:opsworks) { double('Aws::OpsWorks::Client') }
    let(:stack1)   { { stack_id: '1', name: 'Develop' } }
    let(:options)  { { stack: 'Develop' } }
    let(:args)     { ['test1'] }
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(false)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:login)
        .and_return(opsworks)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:stack)
        .with(options[:stack], opsworks)
        .and_return(stack1)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:stop_instance)
        .with(stack1[:stack_id], args[0], opsworks)
    end
    it 'destroys the RDS instance' do
      Skyed::Stop.execute(nil, options, args)
    end
  end
end
