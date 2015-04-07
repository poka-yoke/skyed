require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Run.execute' do
  context 'when initialized' do
    let(:recipe1) { 'recipe1' }
    let(:args)      { [recipe1] }
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(false)
      expect(Skyed::Run)
        .to receive(:check_recipes_exist)
        .with(args)
        .and_return([recipe1])
      expect(Skyed::Run)
        .to receive(:check_vagrant)
      expect(Skyed::Run)
        .to receive(:execute_recipes)
        .with(args)
    end
    it 'runs the recipe' do
      Skyed::Run.execute(nil, nil, args)
    end
  end
  context 'when not initialized' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(true)
      expect(Skyed::Run)
        .to receive(:run)
    end
    it 'uses run method' do
      Skyed::Run.execute(nil, nil, nil)
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

describe 'Skyed::Run.execute_recipes' do
  let(:recipe1)       { 'recipe1' }
  let(:opsworks)      { double('Aws::OpsWorks::Client') }
  let(:access)        { 'AKIAAKIAAKIA' }
  let(:secret)        { 'sGe84ofDSkfo' }
  let(:stack_id)      { 'df345d54-75b4-431b-adb2-eb6b9e549283' }
  let(:cmd_args)      { { 'recipes' => [recipe1] } }
  let(:cmd)           { { name: 'execute_recipes', args: cmd_args } }
  let(:deployment_id) { 'de305d54-75b4-431b-adb2-eb6b9e546013' }
  before(:each) do
    expect(Skyed::Init)
      .to receive(:ow_client)
      .and_return(opsworks)
    expect(Skyed::Settings)
      .to receive(:stack_id)
      .and_return(stack_id)
    expect(opsworks)
      .to receive(:create_deployment)
      .with(stack_id: stack_id, command: cmd)
      .and_return(deployment_id: deployment_id)
  end
  it 'runs the recipe' do
    Skyed::Run.execute_recipes([recipe1])
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
