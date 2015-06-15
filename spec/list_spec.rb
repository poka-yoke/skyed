require 'spec_helper'
require 'skyed'

describe 'Skyed::List.execute' do
  context 'when snapshots was specified and rds was used' do
    let(:args)    { %w(snapshots instance) }
    let(:options) { { rds: true } }
    before(:each) do
      expect(Skyed::List)
        .to receive(:db_snapshots)
        .with(nil, options, args[1..args.length])
    end
    it 'relies on db_snapshots' do
      Skyed::List.execute(nil, options, args)
    end
  end
end

describe 'Skyed::List.db_snapshots' do
  let(:args)    { %w(instance) }
  let(:options) { { rds: true } }
  let(:snapshot1) { double('Aws::RDS::Types::DBSnapshot') }
  let(:snapshot2) { double('Aws::RDS::Types::DBSnapshot') }
  let(:snapshots) { [snapshot1, snapshot2] }
  before(:each) do
    expect(Skyed::Settings)
      .to receive(:empty?)
      .and_return(true)
    expect(Skyed::Init)
      .to receive(:credentials)
    expect(Skyed::AWS::RDS)
      .to receive(:list_snapshots)
      .with(options, args)
      .and_return(snapshots)
    expect(snapshot1)
      .to receive(:db_snapshot_identifier)
      .and_return('rds:instance-2015-06-15-00-06')
    expect(snapshot1)
      .to receive(:db_instance_identifier)
      .and_return('instance')
    expect(snapshot1)
      .to receive(:snapshot_type)
      .and_return('automatic')
    expect(snapshot2)
      .to receive(:db_snapshot_identifier)
      .and_return('rds:instance-2015-06-14-00-06')
    expect(snapshot2)
      .to receive(:db_instance_identifier)
      .and_return('instance')
    expect(snapshot2)
      .to receive(:snapshot_type)
      .and_return('automatic')
    expect($stdout)
      .to receive(:puts)
      .with('rds:instance-2015-06-15-00-06 instance automatic')
    expect($stdout)
      .to receive(:puts)
      .with('rds:instance-2015-06-14-00-06 instance automatic')
  end
  it 'lists db snapshots' do
    Skyed::List.db_snapshots(nil, options, args)
  end
end
