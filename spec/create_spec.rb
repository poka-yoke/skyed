require 'spec_helper'
require 'skyed'

describe 'Skyed::Create.execute' do
  context 'when invoked without RDS option' do
    context 'for new instance creation' do
      let(:options) do
        {
          rds: false
        }
      end
      let(:args)     { [] }
      before(:each) do
        expect(Skyed::Create)
          .to receive(:create_or_start)
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
        it 'creates the OpsWorks machine' do
          Skyed::Create.execute(nil, options, args)
        end
      end
    end
  end
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
          db_parameters_group_name: 'my_db_params',
          stack: nil,
          layer: nil
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
          db_parameters_group_name: 'my_db_params',
          stack: nil,
          layer: nil
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

describe 'Skyed::Create.create_or_start' do
  context 'when stack is not given' do
    let(:options) do
      {
        rds: false,
        stack: nil
      }
    end
    let(:args) { [] }
    it 'fails' do
      expect { Skyed::Create.create_or_start(options, args) }
        .to raise_error
    end
  end
  context 'when stack is given' do
    let(:opsworks) { double('Aws::OpsWorks::Client') }
    let(:stack_id) { '1234-1234-1234-1234' }
    context 'but layer is not' do
      let(:options) do
        {
          rds: false,
          stack: stack_id,
          layer: nil
        }
      end
      let(:args) { [] }
      it 'fails' do
        expect { Skyed::Create.create_or_start(options, args) }
          .to raise_error
      end
    end
    context 'when stack and layer are given' do
      let(:stack_id) { '1234-1234-1234-1234' }
      let(:layer_id) { '4321-4321-4321-4321' }
      let(:options) do
        {
          rds: false,
          stack: stack_id,
          layer: layer_id
        }
      end
      let(:args) { [] }
      before(:each) do
        expect(Skyed::Create)
          .to receive(:login)
          .and_return(opsworks)
      end
      context 'but stack does not exist' do
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack)
            .with(options[:stack], opsworks)
            .and_return(nil)
        end
        it 'fails' do
          expect { Skyed::Create.create_or_start(options, args) }
            .to raise_error
        end
      end
      context 'but layer does not exist' do
        let(:stack) { { stack_id: stack_id, name: 'test2' } }
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack)
            .with(options[:stack], opsworks)
            .and_return(stack)
          expect(Skyed::AWS::OpsWorks)
            .to receive(:layer)
            .with(options[:layer], opsworks)
            .and_return(nil)
        end
        it 'fails' do
          expect { Skyed::Create.create_or_start(options, args) }
            .to raise_error
        end
      end
      context 'and both exist' do
        let(:stack)       { { stack_id: stack_id, name: 'test2' } }
        let(:instance_id) { 'i-3492486' }
        let(:layer) do
          { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
        end
        let(:options) do
          {
            rds: false,
            stack: stack_id,
            layer: layer_id,
            type: 'm1.large'
          }
        end
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack)
            .with(options[:stack], opsworks)
            .and_return(stack)
          expect(Skyed::AWS::OpsWorks)
            .to receive(:layer)
            .with(options[:layer], opsworks)
            .and_return(layer)
        end
        context 'while there is no stopped instance' do
          before(:each) do
            expect(Skyed::AWS::OpsWorks)
              .to receive(:stopped_instances)
              .with({ layer_id: options[:layer] }, opsworks)
              .and_return([])
            expect(Skyed::AWS::OpsWorks)
              .to receive(:create_instance)
              .with(stack_id, layer_id, options[:type], opsworks)
          end
          it 'creates the OpsWorks machine' do
            Skyed::Create.create_or_start(options, args)
          end
        end
        context 'if there are stopped instances' do
          before(:each) do
            expect(Skyed::AWS::OpsWorks)
              .to receive(:stopped_instances)
              .with({ layer_id: options[:layer] }, opsworks)
              .and_return([instance_id])
            expect(Skyed::AWS::OpsWorks)
              .to receive(:start_instance)
              .with(instance_id, opsworks)
          end
          it 'creates the OpsWorks machine' do
            Skyed::Create.create_or_start(options, args)
          end
        end
      end
    end
  end
end
