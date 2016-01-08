require 'require_all'
require_all 'plugins/aws-0.1/lib/aws/rds.rb'

describe 'Skyed::Aws::Rds::Rds#create' do
  it 'creates a Db Instance' do
    rds = Skyed::Aws::Rds::Rds.new
    expect { rds.create }.to raise_error(NotImplementedError)
  end
end

describe 'Skyed::Aws::Rds::Rds#list' do
  it 'lists Db Instances' do
    rds = Skyed::Aws::Rds::Rds.new
    expect { rds.list }.to raise_error(NotImplementedError)
  end
end

describe 'Skyed::Aws::Rds::Rds#destroy' do
  it 'destroys a Db Instance' do
    rds = Skyed::Aws::Rds::Rds.new
    expect { rds.destroy }.to raise_error(NotImplementedError)
  end
end
