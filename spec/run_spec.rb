require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Run.execute' do
  let(:recipe1) { 'recipe1' }
  context 'when invoked with valid recipe' do
    let(:args)      { [recipe1] }
    let(:repo_path) { '/home/ifosch/opsworks' }
    before(:each) do
      expect(Skyed::Run)
        .to receive(:recipe_in_cookbook)
        .with(recipe1)
        .and_return(true)
      expect(Skyed::Settings)
        .to receive(:repo)
        .and_return(repo_path)
    end
    context 'when vagrant is running' do
      let(:opsworks)      { double('AWS::OpsWorks::Client') }
      let(:access)        { 'AKIAAKIAAKIA' }
      let(:secret)        { 'sGe84ofDSkfo' }
      let(:stack_id)      { 'df345d54-75b4-431b-adb2-eb6b9e549283' }
      let(:cmd_args)      { { 'recipes' => [recipe1] } }
      let(:cmd)           { { name: 'execute_recipes', args: cmd_args } }
      let(:deployment_id) { 'de305d54-75b4-431b-adb2-eb6b9e546013' }
      before(:each) do
        expect(Skyed::Run)
          .to receive(:`)
          .with("cd #{repo_path} && vagrant status")
          .and_return('Any output containing running')
        expect(AWS::OpsWorks::Client)
          .to receive(:new)
          .with(access_key_id: access, secret_access_key: secret)
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
        Skyed::Run.execute(nil, nil, args)
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
        expect { Skyed::Run.execute(nil, nil, args) }
          .to raise_error
      end
    end
    context 'but vagrant fails' do
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
        expect { Skyed::Run.execute(nil, nil, args) }
          .to raise_error
      end
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
      expect { Skyed::Run.execute(nil, nil, args) }
        .to raise_error
    end
    context 'when invoked with unexisting recipes' do
      let(:recipe2) { 'recipe2::restart' }
      let(:args)   { [recipe1, recipe2] }
      before(:each) do
        expect(Skyed::Run)
          .to receive(:recipe_in_cookbook)
          .with(recipe2)
          .and_return(false)
      end
      it 'fails' do
        expect { Skyed::Run.execute(nil, nil, args) }
          .to raise_error
      end
    end
    context 'when invoked with existing and unexisting recipes' do
      let(:recipe2) { 'recipe2::restart' }
      let(:args)   { [recipe1, recipe2] }
      before(:each) do
        expect(Skyed::Run)
          .to receive(:recipe_in_cookbook)
          .with(recipe2)
          .and_return(true)
      end
      it 'fails' do
        expect { Skyed::Run.execute(nil, nil, args) }
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
