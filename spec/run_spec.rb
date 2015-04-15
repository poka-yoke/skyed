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
        expect(Skyed::Init)
          .to receive(:ow_client)
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
        expect(Skyed::Init)
          .to_not receive(:ow_client)
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
        expect(Skyed::Init)
          .to receive(:ow_client)
          .and_return(opsworks)
      end
      context 'and stack does not exist' do
        let(:stacks)           { [{ stack_id: other_stack_id, name: 'test1' }] }
        let(:described_stacks) { { stacks: stacks } }
        before(:each) do
          expect(opsworks)
            .to receive(:describe_stacks)
            .and_return(described_stacks)
        end
        it 'fails' do
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and layer does not exist' do
        let(:other_layer_id)   { '8765-8765-8765-8765' }
        let(:described_stacks) { { stacks: stacks } }
        let(:described_layers) { { layers: layers } }
        let(:stacks) do
          [
            { stack_id: other_stack_id, name: 'test1' },
            { stack_id: stack_id, name: 'test2' }
          ]
        end
        let(:layers) do
          [
            { stack_id: stack_id, layer_id: other_layer_id, name: 'test1' }
          ]
        end
        before(:each) do
          expect(opsworks)
            .to receive(:describe_stacks)
            .and_return(described_stacks)
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
        let(:other_layer_id)          { '8765-8765-8765-8765' }
        let(:described_stacks)        { { stacks: stacks } }
        let(:described_layers)        { { layers: layers } }
        let(:described_instances)     { { instances: instances } }
        let(:deploy_id1)              { '123-123-123-123' }
        let(:deploy_id2)              { '321-321-321-321' }
        let(:deploy_status_run)       { { status: 'running' } }
        let(:deploy_status_success)   { { status: 'successful' } }
        let(:stacks) do
          [
            { stack_id: other_stack_id, name: 'test1' },
            { stack_id: stack_id, name: 'test2' }
          ]
        end
        let(:layers) do
          [
            { stack_id: stack_id, layer_id: other_layer_id, name: 'test1' },
            { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
          ]
        end
        let(:instances) do
          [
            { instance_id: '4321-4321-4321-4322', status: 'stopped' },
            { instance_id: '4321-4321-4321-4323', status: 'running' }
          ]
        end
        before(:each) do
          expect(opsworks)
            .to receive(:describe_stacks)
            .and_return(described_stacks)
          expect(opsworks)
            .to receive(:describe_layers)
            .with(stack_id: stack_id)
            .and_return(described_layers)
          expect(opsworks)
            .to receive(:describe_instances)
            .with(layer_id: layer_id)
            .and_return(described_instances)
          expect(opsworks)
            .to receive(:create_deployment)
            .with(
              stack_id: stack_id,
              instance_ids: ['4321-4321-4321-4323'],
              command: { name: 'update_custom_cookbooks' })
            .and_return(deployment_id: deploy_id1)
          expect(opsworks)
            .to receive(:describe_deployments)
            .with(
              deployment_ids: [deploy_id1])
            .and_return(deployments: [deploy_status_run])
          expect(opsworks)
            .to receive(:describe_deployments)
            .with(
              deployment_ids: [deploy_id1])
            .and_return(deployments: [deploy_status_success])
          expect(opsworks)
            .to receive(:create_deployment)
            .with(
              stack_id: stack_id,
              instance_ids: ['4321-4321-4321-4323'],
              command: { name: 'execute_recipes', args: cmd_args })
            .and_return(deployment_id: deploy_id2)
          expect(opsworks)
            .to receive(:describe_deployments)
            .with(
              deployment_ids: [deploy_id2])
            .and_return(deployments: [deploy_status_run])
          expect(opsworks)
            .to receive(:describe_deployments)
            .with(
              deployment_ids: [deploy_id2])
            .and_return(deployments: [deploy_status_success])
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
        expect(Skyed::Init)
          .to receive(:ow_client)
          .and_return(opsworks)
      end
      context 'and stack does not exist' do
        let(:stacks)           { [{ stack_id: other_stack_id, name: 'test1' }] }
        let(:described_stacks) { { stacks: stacks } }
        before(:each) do
          expect(opsworks)
            .to receive(:describe_stacks)
            .and_return(described_stacks)
        end
        it 'fails' do
          expect { Skyed::Run.run(nil, options, args) }
            .to raise_error
        end
      end
      context 'and layer does not exist' do
        let(:other_layer_id)   { '8765-8765-8765-8765' }
        let(:described_stacks) { { stacks: stacks } }
        let(:described_layers) { { layers: layers } }
        let(:stacks) do
          [
            { stack_id: other_stack_id, name: 'test1' },
            { stack_id: stack_id, name: 'test2' }
          ]
        end
        let(:layers) do
          [
            { stack_id: stack_id, layer_id: other_layer_id, name: 'test1' }
          ]
        end
        before(:each) do
          expect(opsworks)
            .to receive(:describe_stacks)
            .and_return(described_stacks)
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
        let(:other_layer_id)          { '8765-8765-8765-8765' }
        let(:described_stacks)        { { stacks: stacks } }
        let(:described_layers)        { { layers: layers } }
        let(:described_instances)     { { instances: instances } }
        let(:deploy_id1)              { '123-123-123-123' }
        let(:deploy_id2)              { '321-321-321-321' }
        let(:deploy_status_run)       { { status: 'running' } }
        let(:deploy_status_success)   { { status: 'successful' } }
        let(:stacks) do
          [
            { stack_id: other_stack_id, name: 'test1' },
            { stack_id: stack_id, name: 'test2' }
          ]
        end
        let(:layers) do
          [
            { stack_id: stack_id, layer_id: other_layer_id, name: 'test1' },
            { stack_id: stack_id, layer_id: layer_id, name: 'test2' }
          ]
        end
        let(:instances) do
          [
            { instance_id: '4321-4321-4321-4322', status: 'stopped' },
            { instance_id: '4321-4321-4321-4323', status: 'running' }
          ]
        end
        before(:each) do
          expect(opsworks)
            .to receive(:describe_stacks)
            .and_return(described_stacks)
          expect(opsworks)
            .to receive(:describe_layers)
            .with(stack_id: stack_id)
            .and_return(described_layers)
          expect(opsworks)
            .to receive(:describe_instances)
            .with(layer_id: layer_id)
            .and_return(described_instances)
          expect(opsworks)
            .to receive(:create_deployment)
            .with(
              stack_id: stack_id,
              instance_ids: ['4321-4321-4321-4323'],
              command: { name: 'update_custom_cookbooks' })
            .and_return(deployment_id: deploy_id1)
          expect(opsworks)
            .to receive(:describe_deployments)
            .with(
              deployment_ids: [deploy_id1])
            .and_return(deployments: [deploy_status_run])
          expect(opsworks)
            .to receive(:describe_deployments)
            .with(
              deployment_ids: [deploy_id1])
            .and_return(deployments: [deploy_status_success])
          expect(opsworks)
            .to receive(:describe_deployments)
            .with(
              deployment_ids: [deploy_id2])
            .and_return(deployments: [deploy_status_run])
          expect(opsworks)
            .to receive(:describe_deployments)
            .with(
              deployment_ids: [deploy_id2])
            .and_return(deployments: [deploy_status_success])
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

describe 'Skyed::Run.execute_recipes' do
  let(:recipe1)       { 'recipe1' }
  let(:opsworks)      { double('Aws::OpsWorks::Client') }
  let(:access)        { 'AKIAAKIAAKIA' }
  let(:secret)        { 'sGe84ofDSkfo' }
  let(:stack_id)      { 'df345d54-75b4-431b-adb2-eb6b9e549283' }
  let(:layer_id)      { 'e1403a56-286e-4b5e-adb2-eb6b9e549283' }
  let(:cmd_args)      { { recipes: [recipe1] } }
  let(:cmd)           { { name: 'execute_recipes', args: cmd_args } }
  let(:deployment_id) { 'de305d54-75b4-431b-adb2-eb6b9e546013' }
  let(:deploy_status_run)      { { status: 'running' } }
  let(:deploy_status_success)  { { status: 'successful' } }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .and_return(stack_id)
    expect(opsworks)
      .to receive(:describe_deployments)
      .with(deployment_ids: [deployment_id])
      .and_return(deployments: [deploy_status_run])
    expect(opsworks)
      .to receive(:describe_deployments)
      .with(deployment_ids: [deployment_id])
      .and_return(deployments: [deploy_status_success])
  end
  context 'without custom_json' do
    before(:each) do
      expect(opsworks)
        .to receive(:create_deployment)
        .with(stack_id: stack_id, command: cmd)
        .and_return(deployment_id: deployment_id)
    end
    it 'runs the recipe' do
      Skyed::Run.execute_recipes(opsworks, [recipe1])
    end
  end
  context 'with custom_json' do
    let(:custom_json) { '{"property": "value"}' }
    before(:each) do
      expect(opsworks)
        .to receive(:create_deployment)
        .with(
          stack_id: stack_id,
          command: cmd,
          custom_json: custom_json)
        .and_return(deployment_id: deployment_id)
    end
    it 'runs the recipe' do
      Skyed::Run.execute_recipes(
        opsworks,
        [recipe1],
        nil,
        custom_json: custom_json)
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
