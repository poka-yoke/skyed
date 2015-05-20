require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Run.execute' do
  let(:recipe1) { 'recipe1' }
  let(:args)    { [recipe1] }
  context 'when initialized' do
    let(:opsworks) { double('Aws::OpsWorks::Client') }
    context 'and no stack given' do
      before(:each) do
        expect(Skyed::Run)
          .to receive(:check_recipes_exist)
          .with(args)
          .and_return([recipe1])
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
          .to_not receive(:check_recipes_exist)
          .with(args)
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
      Skyed::Run.execute(nil, options, args)
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
  end
  context 'when stack and layer ids given' do
    let(:stack_id)         { '1234-1234-1234-1234' }
    let(:layer_id)         { '4321-4321-4321-4321' }
    let(:options) do
      { stack: stack_id, layer: layer_id, wait_interval: 0 }
    end
    context 'without settings defined' do
      let(:opsworks)         { double('Aws::OpsWorks::Client') }
      let(:other_stack_id)   { '5678-5678-5678-5678' }
      before(:each) do
        expect(Skyed::Settings)
          .to receive(:empty?)
          .and_return(true)
        expect(Skyed::Init)
          .to receive(:credentials)
        expect(Skyed::AWS::OpsWorks)
          .to receive(:login)
          .and_return(opsworks)
      end
      context 'and stack does not exist' do
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack_by_id)
            .with(options[:stack], opsworks)
            .and_return(nil)
        end
        it 'fails' do
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and layer does not exist' do
        let(:other_layer_id)   { '8765-8765-8765-8765' }
        let(:described_layers) { { layers: layers } }
        let(:stack)            { { stack_id: stack_id, name: 'test2' } }
        let(:layers) do
          [
            { stack_id: stack_id, layer_id: other_layer_id, name: 'test1' }
          ]
        end
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack_by_id)
            .with(options[:stack], opsworks)
            .and_return(stack)
          expect(opsworks)
            .to receive(:describe_layers)
            .with(stack_id: stack_id)
            .and_return(described_layers)
        end
        it 'fails' do
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and both exist' do
        let(:other_layer_id)   { '8765-8765-8765-8765' }
        let(:described_layers) { { layers: layers } }
        let(:deploy_id1)       { '123-123-123-123' }
        let(:deploy_id2)       { '321-321-321-321' }
        let(:stack)            { { stack_id: stack_id, name: 'test2' } }
        let(:layers) do
          [
            { stack_id: stack_id, layer_id: other_layer_id, name: 'test1' },
            { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
          ]
        end
        let(:described_instances) do
          ['4321-4321-4321-4323']
        end
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack_by_id)
            .with(options[:stack], opsworks)
            .and_return(stack)
          expect(opsworks)
            .to receive(:describe_layers)
            .with(stack_id: stack_id)
            .and_return(described_layers)
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
      let(:other_stack_id)   { '5678-5678-5678-5678' }
      before(:each) do
        expect(Skyed::Settings)
          .to receive(:empty?)
          .and_return(false)
        expect(Skyed::Init)
          .not_to receive(:credentials)
        expect(Skyed::AWS::OpsWorks)
          .to receive(:login)
          .and_return(opsworks)
      end
      context 'and stack does not exist' do
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack_by_id)
            .with(options[:stack], opsworks)
            .and_return(nil)
        end
        it 'fails' do
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and layer does not exist' do
        let(:other_layer_id)   { '8765-8765-8765-8765' }
        let(:described_layers) { { layers: layers } }
        let(:stack)            { { stack_id: stack_id, name: 'test2' } }
        let(:layers) do
          [
            { stack_id: stack_id, layer_id: other_layer_id, name: 'test1' }
          ]
        end
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack_by_id)
            .with(options[:stack], opsworks)
            .and_return(stack)
          expect(opsworks)
            .to receive(:describe_layers)
            .with(stack_id: stack_id)
            .and_return(described_layers)
        end
        it 'fails' do
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and both exist' do
        let(:other_layer_id)   { '8765-8765-8765-8765' }
        let(:described_layers) { { layers: layers } }
        let(:deploy_id1)       { '123-123-123-123' }
        let(:deploy_id2)       { '321-321-321-321' }
        let(:stack)            { { stack_id: stack_id, name: 'test2' } }
        let(:layers) do
          [
            { stack_id: stack_id, layer_id: other_layer_id, name: 'test1' },
            { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
          ]
        end
        let(:described_instances) do
          ['4321-4321-4321-4323']
        end
        before(:each) do
          expect(Skyed::AWS::OpsWorks)
            .to receive(:stack_by_id)
            .with(options[:stack], opsworks)
            .and_return(stack)
          expect(opsworks)
            .to receive(:describe_layers)
            .with(stack_id: stack_id)
            .and_return(described_layers)
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
  before(:each) do
    expect(Skyed::AWS::OpsWorks)
      .to receive(:generate_deploy_params)
      .with(stack_id, cmd, instance_ids: instances)
      .and_return(
        stack_id: stack_id,
        command: cmd,
        instance_ids: instances)
    expect(opsworks)
      .to receive(:create_deployment)
      .with(
        stack_id: stack_id,
        instance_ids: ['4321-4321-4321-4321'],
        command: cmd)
      .and_return(deployment_id: deployment_id)
  end
  context 'when deploy is successful' do
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:wait_for_deploy)
        .with({ deployment_id: deployment_id }, opsworks, 0)
        .and_return(['successful'])
    end
    it 'runs the command' do
      Skyed::Run.update_custom_cookbooks(opsworks, stack_id, instances)
    end
  end
  context 'when deploy is failed' do
    before(:each) do
      expect(Skyed::AWS::OpsWorks)
        .to receive(:wait_for_deploy)
        .with({ deployment_id: deployment_id }, opsworks, 0)
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
        .to receive(:generate_deploy_params)
        .with(stack_id, bare_args, {})
        .and_return(stack_id: stack_id, command: cmd)
      expect(opsworks)
        .to receive(:create_deployment)
        .with(stack_id: stack_id, command: cmd)
        .and_return(deployment_id: deployment_id)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:wait_for_deploy)
        .with({ deployment_id: deployment_id }, opsworks, 0)
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
        .to receive(:generate_deploy_params)
        .with(stack_id, bare_args, custom_json: custom_json)
        .and_return(stack_id: stack_id, command: cmd, custom_json: custom_json)
      expect(opsworks)
        .to receive(:create_deployment)
        .with(
          stack_id: stack_id,
          command: cmd,
          custom_json: custom_json)
        .and_return(deployment_id: deployment_id)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:wait_for_deploy)
        .with({ deployment_id: deployment_id }, opsworks, 0)
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
      expect(opsworks)
        .to receive(:create_deployment)
        .with(stack_id: stack_id, command: cmd)
        .and_return(deployment_id: deployment_id)
      expect(Skyed::AWS::OpsWorks)
        .to receive(:wait_for_deploy)
        .with({ deployment_id: deployment_id }, opsworks, 0)
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
        .to receive(:recipe_in_cookbook)
        .with(recipe1)
        .and_return(true)
    end
    it 'runs the recipe' do
      expect(Skyed::Run.check_recipes_exist(args))
        .to eq [recipe1]
    end
  end
  context 'when invoked with unexisting recipe' do
    let(:args)   { [recipe1] }
    before(:each) do
      expect(Skyed::Run)
        .to receive(:recipe_in_cookbook)
        .with(recipe1)
        .and_return(false)
    end
    it 'fails' do
      expect { Skyed::Run.check_recipes_exist(args) }
        .to raise_error
    end
  end
  context 'when invoked with unexisting recipes' do
    let(:recipe2) { 'recipe2::restart' }
    let(:args)   { [recipe1, recipe2] }
    before(:each) do
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
      expect { Skyed::Run.check_recipes_exist(args) }
        .to raise_error
    end
  end
  context 'when invoked with existing and unexisting recipes' do
    let(:recipe2) { 'recipe2::restart' }
    let(:args)   { [recipe1, recipe2] }
    before(:each) do
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
      expect { Skyed::Run.check_recipes_exist(args) }
        .to raise_error
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
      it 'runs the recipe' do
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
      it 'runs the recipe' do
        expect(Skyed::Run.recipe_in_cookbook(recipe2))
          .to eq(false)
      end
    end
  end
end
