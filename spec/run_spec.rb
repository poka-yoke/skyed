require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Run.execute' do
  let(:recipe1) { 'recipe1' }
  let(:args)    { [recipe1] }
  let(:options) { nil }
  before(:each) do
    expect(Skyed::Run)
      .to receive(:check_recipes_exist)
      .with(options, args)
      .and_return([recipe1])
  end
  context 'when initialized' do
    let(:opsworks) { double('Aws::OpsWorks::Client') }
    context 'and no stack given' do
      before(:each) do
        expect(Skyed::Run)
          .to receive(:check_vagrant)
        expect(Skyed::AWS::OpsWorks)
          .to receive(:login)
          .and_return(opsworks)
        expect(Skyed::Run)
          .to receive(:execute_recipes)
          .with(opsworks, args)
      end
      it 'runs the recipe' do
        Skyed::Run.execute(nil, nil, args)
      end
    end
    context 'but stack was given' do
      let(:options) { { stack: '1234-1234-1234-2134' } }
      before(:each) do
        expect(Skyed::Run)
          .to_not receive(:check_vagrant)
        expect(Skyed::AWS::OpsWorks)
          .to_not receive(:login)
        expect(Skyed::Run)
          .to_not receive(:execute_recipes)
          .with(opsworks, args)
        expect(Skyed::Run)
          .to receive(:run)
          .with(nil, options, args)
      end
      it 'runs the recipe against the stack' do
        Skyed::Run.execute(nil, options, args)
      end
    end
  end
  context 'when not initialized' do
    let(:options) { { stack: '1234-1234-1234-2134' } }
    before(:each) do
      expect(Skyed::Run)
        .to receive(:run)
    end
    it 'uses run method' do
      Skyed::Run.execute(nil, options, [recipe1])
    end
  end
end

describe 'Skyed::Run.run' do
  let(:recipe1)  { 'recipe1' }
  let(:args) { [recipe1] }
  let(:cmd_args) { { recipes: [recipe1] } }
  let(:options)  { { stack: nil, wait_interval: 0 } }
  context 'when no stack given' do
    it 'fails' do
      expect { Skyed::Run.run(nil, options, args) }
        .to raise_error
    end
  end
  context 'when stack given but no layer is given' do
    let(:stack_id) { '1234-1234-1234-1234' }
    let(:options)  { { stack: stack_id, layer: nil, wait_interval: 0 } }
    it 'fails' do
      expect { Skyed::Run.run(nil, options, args) }
        .to raise_error
    end
    context 'but instance name is given' do
      let(:instance_name) { 'test1' }
      let(:opsworks)      { double('Aws::OpsWorks::Client') }
      let(:options) do
        { stack: stack_id, instance: instance_name, wait_interval: 0 }
      end
      before(:each) do
        expect(Skyed::AWS::OpsWorks)
          .to receive(:login)
          .and_return(opsworks)
      end
      context 'without settings defined' do
        before(:each) do
          expect(Skyed::Settings)
            .to receive(:empty?)
            .and_return(true)
          expect(Skyed::Init)
            .to receive(:credentials)
        end
        context 'and stack does not exist' do
          before(:each) do
            expect(Skyed::AWS::OpsWorks)
              .to receive(:stack)
              .with(options[:stack], opsworks)
              .and_return(nil)
          end
          it 'fails' do
            expect { Skyed::Run.run(nil, options, args) }
              .to raise_error
          end
        end
        context 'and layer for instance does not exist' do
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
            expect(Skyed::AWS::OpsWorks)
              .to receive(:layer)
              .with(options[:instance], opsworks, stack_id)
              .and_return(nil)
          end
          it 'fails' do
            expect { Skyed::Run.run(nil, options, args) }
              .to raise_error
          end
        end
        context 'and both exist' do
          let(:layer_id)            { '123-123-123-123' }
          let(:deploy_id1)          { '123-123-123-123' }
          let(:deploy_id2)          { '321-321-321-321' }
          let(:stack)               { { stack_id: stack_id, name: 'test2' } }
          let(:instance1) do
            Instance.new(
              '4321-4321-4321-4323',
              instance_name,
              stack_id,
              [layer_id],
              'online',
              nil,
              nil
            )
          end
          let(:layer) do
            { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
          end
          before(:each) do
            expect(Skyed::AWS::OpsWorks)
              .to receive(:stack)
              .with(options[:stack], opsworks)
              .and_return(stack)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:layer)
              .with(options[:layer], opsworks)
              .and_return(nil)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:layer)
              .with(options[:instance], opsworks, stack_id)
              .and_return(layer)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:instance_by_name)
              .with(instance_name, stack_id, opsworks)
              .and_return(instance1)
            expect(opsworks)
              .to receive(:create_deployment)
              .with(
                stack_id: stack_id,
                instance_ids: ['4321-4321-4321-4323'],
                command: { name: 'update_custom_cookbooks' })
              .and_return(deployment_id: deploy_id1)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:wait_for_deploy)
              .with({ deployment_id: deploy_id1 }, opsworks, 0)
              .once
              .and_return(['successful'])
            expect(opsworks)
              .to receive(:create_deployment)
              .with(
                stack_id: stack_id,
                instance_ids: ['4321-4321-4321-4323'],
                command: { name: 'execute_recipes', args: cmd_args })
              .and_return(deployment_id: deploy_id2)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:wait_for_deploy)
              .with({ deployment_id: deploy_id2 }, opsworks, 0)
              .once
              .and_return(['successful'])
          end
          it 'runs' do
            Skyed::Run.run(nil, options, args)
          end
        end
      end
      context 'with settings defined' do
        before(:each) do
          expect(Skyed::Settings)
            .to receive(:empty?)
            .and_return(false)
        end
        context 'and stack does not exist' do
          before(:each) do
            expect(Skyed::AWS::OpsWorks)
              .to receive(:stack)
              .with(options[:stack], opsworks)
              .and_return(nil)
          end
          it 'fails' do
            expect { Skyed::Run.run(nil, options, args) }
              .to raise_error
          end
        end
        context 'and layer for instance does not exist' do
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
            expect(Skyed::AWS::OpsWorks)
              .to receive(:layer)
              .with(options[:instance], opsworks, stack_id)
              .and_return(nil)
          end
          it 'fails' do
            expect { Skyed::Run.run(nil, options, args) }
              .to raise_error
          end
        end
        context 'and both exist' do
          let(:layer_id)            { '123-123-123-123' }
          let(:deploy_id1)          { '123-123-123-123' }
          let(:deploy_id2)          { '321-321-321-321' }
          let(:stack)               { { stack_id: stack_id, name: 'test2' } }
          let(:instance1) do
            Instance.new(
              '4321-4321-4321-4323',
              instance_name,
              stack_id,
              [layer_id],
              'online',
              nil,
              nil
            )
          end
          let(:layer) do
            { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
          end
          before(:each) do
            expect(Skyed::AWS::OpsWorks)
              .to receive(:stack)
              .with(options[:stack], opsworks)
              .and_return(stack)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:layer)
              .with(options[:layer], opsworks)
              .and_return(nil)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:layer)
              .with(options[:instance], opsworks, stack_id)
              .and_return(layer)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:instance_by_name)
              .with(instance_name, stack_id, opsworks)
              .and_return(instance1)
            expect(opsworks)
              .to receive(:create_deployment)
              .with(
                stack_id: stack_id,
                instance_ids: ['4321-4321-4321-4323'],
                command: { name: 'update_custom_cookbooks' })
              .and_return(deployment_id: deploy_id1)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:wait_for_deploy)
              .with({ deployment_id: deploy_id1 }, opsworks, 0)
              .once
              .and_return(['successful'])
            expect(opsworks)
              .to receive(:create_deployment)
              .with(
                stack_id: stack_id,
                instance_ids: ['4321-4321-4321-4323'],
                command: { name: 'execute_recipes', args: cmd_args })
              .and_return(deployment_id: deploy_id2)
            expect(Skyed::AWS::OpsWorks)
              .to receive(:wait_for_deploy)
              .with({ deployment_id: deploy_id2 }, opsworks, 0)
              .once
              .and_return(['successful'])
          end
          it 'runs' do
            Skyed::Run.run(nil, options, args)
          end
        end
      end
    end
  end
  context 'when stack and layer ids given' do
    let(:stack_id)         { '1234-1234-1234-1234' }
    let(:layer_id)         { '4321-4321-4321-4321' }
    let(:options) do
      { stack: stack_id, layer: layer_id, wait_interval: 0 }
    end
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:login)
        .and_return(opsworks)
    end
    context 'without settings defined' do
      let(:opsworks)         { double('Aws::OpsWorks::Client') }
      before(:each) do
        expect(Skyed::Settings)
          .to receive(:empty?)
          .and_return(true)
        expect(Skyed::Init)
          .to receive(:credentials)
      end
      context 'and stack does not exist' do
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack)
            .with(options[:stack], opsworks)
            .and_return(nil)
        end
        it 'fails' do
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and layer does not exist' do
        let(:stack)            { { stack_id: stack_id, name: 'test2' } }
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
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and both exist' do
        let(:deploy_id1)          { '123-123-123-123' }
        let(:deploy_id2)          { '321-321-321-321' }
        let(:stack)               { { stack_id: stack_id, name: 'test2' } }
        let(:described_instances) { ['4321-4321-4321-4323'] }
        let(:layer) do
          { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
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
          expect(Skyed::AWS::OpsWorks)
            .to receive(:running_instances)
            .with({ layer_id: layer_id }, opsworks)
            .and_return(described_instances)
          expect(opsworks)
            .to receive(:create_deployment)
            .with(
              stack_id: stack_id,
              instance_ids: ['4321-4321-4321-4323'],
              command: { name: 'update_custom_cookbooks' })
            .and_return(deployment_id: deploy_id1)
          expect(Skyed::AWS::OpsWorks)
            .to receive(:wait_for_deploy)
            .with({ deployment_id: deploy_id1 }, opsworks, 0)
            .once
            .and_return(['successful'])
          expect(opsworks)
            .to receive(:create_deployment)
            .with(
              stack_id: stack_id,
              instance_ids: ['4321-4321-4321-4323'],
              command: { name: 'execute_recipes', args: cmd_args })
            .and_return(deployment_id: deploy_id2)
          expect(Skyed::AWS::OpsWorks)
            .to receive(:wait_for_deploy)
            .with({ deployment_id: deploy_id2 }, opsworks, 0)
            .once
            .and_return(['successful'])
        end
        it 'runs' do
          Skyed::Run.run(nil, options, args)
        end
      end
    end
    context 'with settings defined' do
      let(:opsworks)         { double('Aws::OpsWorks::Client') }
      before(:each) do
        expect(Skyed::Settings)
          .to receive(:empty?)
          .and_return(false)
      end
      context 'and stack does not exist' do
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack)
            .with(options[:stack], opsworks)
            .and_return(nil)
        end
        it 'fails' do
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and layer does not exist' do
        let(:stack)            { { stack_id: stack_id, name: 'test2' } }
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
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and both exist' do
        let(:deploy_id1)          { '123-123-123-123' }
        let(:deploy_id2)          { '321-321-321-321' }
        let(:stack)               { { stack_id: stack_id, name: 'test2' } }
        let(:described_instances) { ['4321-4321-4321-4323'] }
        let(:layer) do
          { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
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
          expect(Skyed::AWS::OpsWorks)
            .to receive(:running_instances)
            .with({ layer_id: layer_id }, opsworks)
            .and_return(described_instances)
          expect(opsworks)
            .to receive(:create_deployment)
            .with(
              stack_id: stack_id,
              instance_ids: ['4321-4321-4321-4323'],
              command: { name: 'update_custom_cookbooks' })
            .and_return(deployment_id: deploy_id1)
          expect(Skyed::AWS::OpsWorks)
            .to receive(:wait_for_deploy)
            .with({ deployment_id: deploy_id1 }, opsworks, 0)
            .once
            .and_return(['successful'])
          expect(Skyed::AWS::OpsWorks)
            .to receive(:wait_for_deploy)
            .with({ deployment_id: deploy_id2 }, opsworks, 0)
            .once
            .and_return(['successful'])
        end
        context 'and no custom json was provided' do
          before(:each) do
            expect(opsworks)
              .to receive(:create_deployment)
              .with(
                stack_id: stack_id,
                instance_ids: ['4321-4321-4321-4323'],
                command: { name: 'execute_recipes', args: cmd_args })
              .and_return(deployment_id: deploy_id2)
          end
          it 'runs' do
            Skyed::Run.run(nil, options, args)
          end
        end
        context 'and custom json was provided' do
          let(:custom_json_str) { '{"property": "value"}' }
          let(:options) do
            {
              stack: stack_id,
              layer: layer_id,
              wait_interval: 0,
              custom_json: custom_json_str
            }
          end
          before(:each) do
            expect(opsworks)
              .to receive(:create_deployment)
              .with(
                stack_id: stack_id,
                instance_ids: ['4321-4321-4321-4323'],
                command: { name: 'execute_recipes', args: cmd_args },
                custom_json: custom_json_str)
              .and_return(deployment_id: deploy_id2)
          end
          it 'runs' do
            Skyed::Run.run(nil, options, args)
          end
        end
      end
    end
  end
end

describe 'Skyed::Run.update_custom_cookbooks' do
  let(:opsworks)      { double('Aws::OpsWorks::Client') }
  let(:access)        { 'AKIAAKIAAKIA' }
  let(:secret)        { 'sGe84ofDSkfo' }
  let(:stack_id)      { 'df345d54-75b4-431b-adb2-eb6b9e549283' }
  let(:layer_id)      { 'e1403a56-286e-4b5e-adb2-eb6b9e549283' }
  let(:cmd)           { { name: 'update_custom_cookbooks' } }
  let(:deployment_id) { 'de305d54-75b4-431b-adb2-eb6b9e546013' }
  let(:instances)     { ['4321-4321-4321-4321'] }
  context 'when deploy is successful' do
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:deploy)
        .with(
          stack_id: stack_id,
          command: cmd,
          instance_ids: instances,
          client: opsworks,
          wait_interval: 0)
        .and_return(['successful'])
    end
    it 'runs the command' do
      Skyed::Run.update_custom_cookbooks(opsworks, stack_id, instances)
    end
  end
  context 'when deploy is failed' do
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:deploy)
        .with(
          stack_id: stack_id,
          command: cmd,
          instance_ids: instances,
          client: opsworks,
          wait_interval: 0)
        .and_return(['failed'])
    end
    it 'fails' do
      expect do
        Skyed::Run.update_custom_cookbooks(
          opsworks,
          stack_id,
          instances)
      end.to raise_error
    end
  end
end

describe 'Skyed::Run.execute_recipes' do
  let(:recipe1)       { 'recipe1' }
  let(:opsworks)      { double('Aws::OpsWorks::Client') }
  let(:access)        { 'AKIAAKIAAKIA' }
  let(:secret)        { 'sGe84ofDSkfo' }
  let(:stack_id)      { 'df345d54-75b4-431b-adb2-eb6b9e549283' }
  let(:layer_id)      { 'e1403a56-286e-4b5e-adb2-eb6b9e549283' }
  let(:bare_args)     { { name: 'execute_recipes', recipes: [recipe1] } }
  let(:cmd_args)      { { recipes: [recipe1] } }
  let(:cmd)           { { name: 'execute_recipes', args: cmd_args } }
  let(:deployment_id) { 'de305d54-75b4-431b-adb2-eb6b9e546013' }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .and_return(stack_id)
  end
  context 'without custom_json' do
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:deploy)
        .with(
          stack_id: stack_id,
          command: bare_args,
          instance_ids: nil,
          client: opsworks,
          wait_interval: 0)
        .and_return(['successful'])
    end
    it 'runs the recipe' do
      Skyed::Run.execute_recipes(opsworks, [recipe1])
    end
  end
  context 'with custom_json' do
    let(:custom_json) { '{"property": "value"}' }
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:deploy)
        .with(
          stack_id: stack_id,
          command: bare_args,
          instance_ids: nil,
          custom_json: custom_json,
          client: opsworks,
          wait_interval: 0)
        .and_return(['successful'])
    end
    it 'runs the recipe' do
      Skyed::Run.execute_recipes(
        opsworks,
        [recipe1],
        nil,
        custom_json: custom_json)
    end
  end
  context 'when deploy is failed' do
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:deploy)
        .with(
          stack_id: stack_id,
          command: bare_args,
          instance_ids: nil,
          client: opsworks,
          wait_interval: 0)
        .and_return(['failed'])
    end
    it 'fails' do
      expect do
        Skyed::Run.execute_recipes(
          opsworks,
          [recipe1])
      end.to raise_error
    end
  end
end

describe 'Skyed::Run.check_vagrant' do
  let(:repo_path) { '/home/ifosch/opsworks' }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:repo)
      .and_return(repo_path)
  end
  context 'when vagrant is running' do
    before(:each) do
      expect(Skyed::Run)
        .to receive(:`)
        .with("cd #{repo_path} && vagrant status")
        .and_return('Any output containing running')
    end
    it 'runs ok' do
      Skyed::Run.check_vagrant
    end
  end
  context 'when vagrant is not running' do
    before(:each) do
      expect(Skyed::Run)
        .to receive(:`)
        .with("cd #{repo_path} && vagrant status")
        .and_return('Any output containing anything else')
    end
    it 'fails' do
      expect { Skyed::Run.check_vagrant }
        .to raise_error
    end
  end
  context 'when vagrant fails' do
    before(:each) do
      expect(Skyed::Run)
        .to receive(:`)
        .with("cd #{repo_path} && vagrant status")
        .and_return('Any output failing')
      expect($CHILD_STATUS)
        .to receive(:success?)
        .and_return(false)
    end
    it 'fails' do
      expect { Skyed::Run.check_vagrant }
        .to raise_error
    end
  end
end

describe 'Skyed::Run.check_recipes_exist' do
  let(:recipe1) { 'recipe1' }
  context 'when invoked with valid recipe' do
    let(:args)      { [recipe1] }
    let(:repo_path) { '/home/ifosch/opsworks' }
    before(:each) do
      expect(Skyed::Run)
        .to receive(:settings)
        .with(nil)
      expect(Skyed::Run)
        .to receive(:recipe_in_cookbook)
        .with(recipe1)
        .and_return(true)
    end
    it 'runs the recipe' do
      expect(Skyed::Run.check_recipes_exist(nil, args))
        .to eq [recipe1]
    end
  end
  context 'when invoked with unexisting recipe' do
    let(:args)   { [recipe1] }
    before(:each) do
      expect(Skyed::Run)
        .to receive(:settings)
        .with(nil)
      expect(Skyed::Run)
        .to receive(:recipe_in_cookbook)
        .with(recipe1)
        .and_return(false)
    end
    it 'fails' do
      expect { Skyed::Run.check_recipes_exist(nil, args) }
        .to raise_error
    end
  end
  context 'when invoked with unexisting recipes' do
    let(:recipe2) { 'recipe2::restart' }
    let(:args)   { [recipe1, recipe2] }
    before(:each) do
      expect(Skyed::Run)
        .to receive(:settings)
        .with(nil)
      expect(Skyed::Run)
        .to receive(:recipe_in_cookbook)
        .with(recipe1)
        .and_return(false)
      expect(Skyed::Run)
        .to receive(:recipe_in_cookbook)
        .with(recipe2)
        .and_return(false)
    end
    it 'fails' do
      expect { Skyed::Run.check_recipes_exist(nil, args) }
        .to raise_error
    end
  end
  context 'when invoked with existing and unexisting recipes' do
    let(:recipe2) { 'recipe2::restart' }
    let(:args)   { [recipe1, recipe2] }
    before(:each) do
      expect(Skyed::Run)
        .to receive(:settings)
        .with(nil)
      expect(Skyed::Run)
        .to receive(:recipe_in_cookbook)
        .with(recipe1)
        .and_return(false)
      expect(Skyed::Run)
        .to receive(:recipe_in_cookbook)
        .with(recipe2)
        .and_return(true)
    end
    it 'fails' do
      expect { Skyed::Run.check_recipes_exist(nil, args) }
        .to raise_error
    end
  end
  context 'when a stack was given' do
    let(:options) { { stack: '1234-1234-1234-2134' } }
    before(:each) do
      expect(Skyed::Run)
        .to receive(:settings)
        .with(options)
    end
    context 'and invoked with valid recipe' do
      let(:args)      { [recipe1] }
      let(:repo_path) { '/home/ifosch/opsworks' }
      before(:each) do
        expect(Skyed::Run)
          .to receive(:recipe_in_remote)
          .with(options, recipe1)
          .and_return(true)
      end
      it 'runs the recipe' do
        expect(Skyed::Run.check_recipes_exist(options, args))
          .to eq [recipe1]
      end
    end
    context 'and invoked with unexisting recipe' do
      let(:args)   { [recipe1] }
      before(:each) do
        expect(Skyed::Run)
          .to receive(:recipe_in_remote)
          .with(options, recipe1)
          .and_return(false)
      end
      it 'fails' do
        expect { Skyed::Run.check_recipes_exist(options, args) }
          .to raise_error
      end
    end
    context 'and invoked with unexisting recipes' do
      let(:recipe2) { 'recipe2::restart' }
      let(:args)   { [recipe1, recipe2] }
      before(:each) do
        expect(Skyed::Run)
          .to receive(:recipe_in_remote)
          .with(options, recipe1)
          .and_return(false)
        expect(Skyed::Run)
          .to receive(:recipe_in_remote)
          .with(options, recipe2)
          .and_return(false)
      end
      it 'fails' do
        expect { Skyed::Run.check_recipes_exist(options, args) }
          .to raise_error
      end
    end
    context 'and invoked with existing and unexisting recipes' do
      let(:recipe2) { 'recipe2::restart' }
      let(:args)   { [recipe1, recipe2] }
      before(:each) do
        expect(Skyed::Run)
          .to receive(:recipe_in_remote)
          .with(options, recipe1)
          .and_return(false)
        expect(Skyed::Run)
          .to receive(:recipe_in_remote)
          .with(options, recipe2)
          .and_return(true)
      end
      it 'fails' do
        expect { Skyed::Run.check_recipes_exist(options, args) }
          .to raise_error
      end
    end
  end
end

describe 'Skyed::Run.recipe_in_cookbook' do
  let(:recipe1)    { 'recipe1' }
  let(:repo_path)  { '/home/ifosch/opsworks' }
  context 'when checking default recipe' do
    context 'which does not exist' do
      before(:each) do
        expect(Skyed::Settings)
          .to receive(:repo)
          .and_return(repo_path)
        expect(File)
          .to receive(:exist?)
          .with(File.join(repo_path, recipe1, 'recipes', 'default.rb'))
          .and_return(false)
      end
      it 'validates the recipe' do
        expect(Skyed::Run.recipe_in_cookbook(recipe1))
          .to eq(false)
      end
    end
  end
  context 'when checking specific recipe' do
    context 'which does not exist' do
      let(:cookbook)   { 'recipe2' }
      let(:recipe)     { 'start' }
      let(:recipe2)    { "#{cookbook}::#{recipe}" }
      before(:each) do
        expect(Skyed::Settings)
          .to receive(:repo)
          .and_return(repo_path)
        expect(File)
          .to receive(:exist?)
          .with(File.join(repo_path, cookbook, 'recipes', "#{recipe}.rb"))
          .and_return(false)
      end
      it 'validates the recipe' do
        expect(Skyed::Run.recipe_in_cookbook(recipe2))
          .to eq(false)
      end
    end
  end
  context 'when using a different repo' do
    let(:repo_path2)  { '/home/ifosch/opsworks' }
    context 'when checking default recipe' do
      context 'which does not exist' do
        before(:each) do
          expect(Skyed::Settings)
            .not_to receive(:repo)
          expect(File)
            .to receive(:exist?)
            .with(File.join(repo_path2, recipe1, 'recipes', 'default.rb'))
            .and_return(false)
        end
        it 'validates the recipe' do
          expect(Skyed::Run.recipe_in_cookbook(recipe1, repo_path2))
            .to eq(false)
        end
      end
    end
    context 'when checking specific recipe' do
      context 'which does not exist' do
        let(:cookbook)   { 'recipe2' }
        let(:recipe)     { 'start' }
        let(:recipe2)    { "#{cookbook}::#{recipe}" }
        before(:each) do
          expect(Skyed::Settings)
            .not_to receive(:repo)
          expect(File)
            .to receive(:exist?)
            .with(File.join(repo_path2, cookbook, 'recipes', "#{recipe}.rb"))
            .and_return(false)
        end
        it 'validates the recipe' do
          expect(Skyed::Run.recipe_in_cookbook(recipe2, repo_path2))
            .to eq(false)
        end
      end
    end
  end
end

describe 'Skyed::Run.recipe_in_remote' do
  let(:opsworks)       { double('Aws::OpsWorks::Client') }
  let(:stack_id)       { '1234-1234-1234-2134' }
  let(:options)        { { stack: stack_id } }
  let(:recipe1)        { 'recipe1' }
  let(:repo_path)      { '/home/ifosch/opsworks' }
  let(:temporal_clone) { '/tmp/skyed.2a890f9876' }
  let(:url)            { 'git@github.com:/user/repo.git' }
  let(:stack) do
    {
      stack_id: stack_id,
      name: 'test2',
      custom_cookbooks_source: {
        type: 'git',
        url: url,
        username: 'user',
        revision: 'master'
      }
    }
  end
  before(:each) do
    expect(Skyed::Run)
      .to receive(:login)
      .and_return(opsworks)
    expect(Skyed::AWS::OpsWorks)
      .to receive(:stack)
      .with(options[:stack], opsworks)
      .and_return(stack)
    expect(Skyed::Git)
      .to receive(:clone_stack_remote)
      .with(stack, options)
      .and_return(temporal_clone)
    expect(Skyed::Run)
      .to receive(:recipe_in_cookbook)
      .with(recipe1, temporal_clone)
      .and_return(true)
  end
  it 'checks the recipe exists in remote' do
    expect(Skyed::Run.recipe_in_remote(options, recipe1))
      .to eq true
  end
end
