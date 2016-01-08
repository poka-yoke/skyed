require 'require_all'
require_all 'plugins/aws-0.1/lib/aws.rb'

describe 'Skyed::Aws#list' do
  it 'lists AWS accounts' do
    aws = Skyed::Aws.new
    expect { aws.list }.to raise_error(NotImplementedError)
  end
end
