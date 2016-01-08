require 'require_all'
require_all 'plugins/aws-0.1/lib/aws/ow.rb'

describe 'Skyed::Aws::Ow::Ow#create' do
  it 'creates a OpsWorks object' do
    ow = Skyed::Aws::Ow::Ow.new
    expect { ow.create }.to raise_error(NotImplementedError)
  end
end

describe 'Skyed::Aws::Ow::Ow#list' do
  it 'lists OpsWorks objects' do
    ow = Skyed::Aws::Ow::Ow.new
    expect { ow.list }.to raise_error(NotImplementedError)
  end
end

describe 'Skyed::Aws::Ow::Ow#destroy' do
  it 'destroys OpsWorks objects' do
    ow = Skyed::Aws::Ow::Ow.new
    expect { ow.destroy }.to raise_error(NotImplementedError)
  end
end

describe 'Skyed::Aws::Ow::Ow#execute' do
  it 'executes commands on OpsWorks objects' do
    ow = Skyed::Aws::Ow::Ow.new
    expect { ow.execute }.to raise_error(NotImplementedError)
  end
end

describe 'Skyed::Aws::Ow::Ow#stop' do
  it 'stops OpsWorks objects' do
    ow = Skyed::Aws::Ow::Ow.new
    expect { ow.stop }.to raise_error(NotImplementedError)
  end
end
