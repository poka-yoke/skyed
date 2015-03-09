require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Deploy.execute' do
  let(:repo_path) { '/home/ifosch/projects/myrepo/.git' }
  let(:branch)    { double('branch') }
  context 'when initialized' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(false)
      expect(Skyed::Settings)
        .to receive(:repo)
        .and_return(repo_path)
      expect(Skyed::Deploy)
        .to receive(:`)
        .with("cd #{repo_path} && vagrant up")
        .and_return('Any output')
    end
    context 'and vagrant runs ok' do
      before(:each) do
        expect($CHILD_STATUS)
          .to receive(:success?)
          .twice
          .and_return(true)
      end
      it 'deploys in local vagrant' do
        expect(Skyed::Deploy.execute(nil))
          .to eq(true)
      end
    end
    context 'but vagrant fails' do
      before(:each) do
        expect($CHILD_STATUS)
          .to receive(:success?)
          .and_return(false)
      end
      it 'deploying in local vagrant' do
        expect { Skyed::Deploy.execute(nil) }
          .to raise_error(RuntimeError, 'Any output')
      end
    end
  end
  context 'when not initialized' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(true)
    end
    it 'fails when not initialized' do
      expect { Skyed::Deploy.execute(nil) }
        .to raise_error
    end
  end
end
