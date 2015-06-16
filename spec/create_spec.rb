require 'spec_helper'
require 'skyed'

describe 'Skyed::Create.execute' do
  context 'when invoked with RDS option' do
    context 'for new instance creation' do
      let(:options) do
        {
          rds: true,
          size: 100,
          type: 'm1.large',
          user: 'root',
          pass: 'pass',
          db_security_group_name: 'rds-launch-wizard',
          db_parameters_group_name: 'my_db_params'
        }
      end
      let(:create_args) do
        {
          size: 100,
          type: 'm1.large',
          user: 'root',
          pass: 'pass',
          db_security_group_name: 'rds-launch-wizard',
          db_parameters_group_name: 'my_db_params'
        }
      end
      let(:args)     { ['my-rds'] }
      let(:endpoint) { 'my-rds.c7werpdeshqu.us-east-1.rds.amazonaws.com:5432' }
      before(:each) do
        expect(Skyed::AWS::RDS)
          .to receive(:create_instance)
          .with('my-rds', create_args)
          .and_return(endpoint)
      end
      context 'and not initialized' do
        before(:each) do
          expect(Skyed::Settings)
            .to receive(:empty?)
            .and_return(true)
          expect(Skyed::Init)
            .to receive(:credentials)
        end
        it 'creates the RDS machine' do
          Skyed::Create.execute(nil, options, args)
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
        it 'creates the RDS machine' do
          Skyed::Create.execute(nil, options, args)
        end
      end
    end
    context 'for snapshot restoring' do
      let(:options) do
        {
          rds: true,
          size: 100,
          type: 'm1.large',
          user: 'root',
          pass: 'pass',
          db_security_group_name: 'rds-launch-wizard',
          db_parameters_group_name: 'my_db_params'
        }
      end
      let(:create_args) do
        {
          size: 100,
          type: 'm1.large',
          user: 'root',
          pass: 'pass',
          db_security_group_name: 'rds-launch-wizard',
          db_parameters_group_name: 'my_db_params'
        }
      end
      let(:args)     { ['my-rds', 'rds:my-rds-2015-06-02-00-06'] }
      let(:endpoint) { 'my-rds.c7werpdeshqu.us-east-1.rds.amazonaws.com:5432' }
      before(:each) do
        expect(Skyed::AWS::RDS)
          .to receive(:create_instance_from_snapshot)
          .with('my-rds', 'rds:my-rds-2015-06-02-00-06', create_args)
          .and_return(endpoint)
      end
      context 'and not initialized' do
        before(:each) do
          expect(Skyed::Settings)
            .to receive(:empty?)
            .and_return(true)
          expect(Skyed::Init)
            .to receive(:credentials)
        end
        it 'creates the RDS machine' do
          Skyed::Create.execute(nil, options, args)
        end
      end
    end
  end
end
