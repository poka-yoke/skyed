require 'require_all'
require_all 'plugins/aws-0.1/lib/aws/elb.rb'

describe 'Skyed::Aws::Elb::Elb#check' do
  it 'checks instance status in ELB' do
    elb = Skyed::Aws::Elb::Elb.new
    expect { elb.check }.to raise_error(NotImplementedError)
  end
end
