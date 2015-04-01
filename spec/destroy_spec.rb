require 'spec_helper'
require 'skyed'
require 'highline/import'

describe 'Skyed::Destroy.execute' do
  let(:repo_path) { '/home/ifosch/opsworks' }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:repo)
      .and_return(repo_path)
  end
  context 'when vagrant machine is running' do
    before(:each) do
      expect(Skyed::Destroy)
        .to receive(:`)
        .with("cd #{repo_path} && vagrant destroy -f")
    end
    it 'destroys the vagrant machine' do
      Skyed::Destroy.execute(nil, nil, nil)
    end
  end
end
