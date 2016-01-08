require 'skyed/settings'

describe 'Skyed::Settings#list' do
  it 'lists Skyed settings' do
    settings = Skyed::Settings.new
    expect { settings.list }.to raise_error(NotImplementedError)
  end
end
