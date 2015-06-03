require 'spec_helper'
require 'skyed'

describe 'Skyed::Utils.export_credentials' do
  let(:access) { 'AIKA' }
  let(:secret) { 'Z3Mw' }
  before(:all) do
    @access = ENV['AWS_ACCESS_KEY']
    @secret = ENV['AWS_SECRET_KEY']
  end
  before do
    expect(Skyed::Settings)
      .to receive(:access_key)
      .and_return(access)
    expect(Skyed::Settings)
      .to receive(:secret_key)
      .and_return(secret)
  end
  after(:all) do
    ENV['AWS_ACCESS_KEY'] = @access
    ENV['AWS_SECRET_KEY'] = @secret
  end
  it 'exports AWS_ACCESS_KEY and AWS_SECRET_KEY with corresponding values' do
    Skyed::Utils.export_credentials
    expect(ENV['AWS_ACCESS_KEY']).to eq(access)
    expect(ENV['AWS_ACCESS_KEY']).to eq(access)
  end
end

describe 'Skyed::Utils.create_template' do
  let(:base)          { '/tmp' }
  let(:subpath)       { 'file' }
  let(:template_file) { 'some_template.erb' }
  let(:templates_path) do
    '/Users/ifosch/src/github.com/ifosch/skyed/templates'
  end
  let(:template_content) do
    '[default]\nregion = {{ aws_default_region }}'
  end
  let(:template)      { double('ERB') }
  let(:file)          { double('File') }
  let(:b)             { double('Bindings') }
  before(:each) do
    expect(Skyed::Utils)
      .to receive(:binding)
      .and_return(b)
    expect(File)
      .to receive(:dirname)
      .at_least(1)
      .and_return('/Users/ifosch/src/github.com/ifosch/skyed')
    expect(File)
      .to receive(:read)
      .with("#{templates_path}/some_template.erb")
      .and_return(template_content)
    expect(ERB)
      .to receive(:new)
      .with(template_content)
      .and_return(template)
    expect(File)
      .to receive(:open)
      .with('/tmp/file', 'w')
      .and_return(file)
  end
  it 'creates the file from template' do
    Skyed::Utils.create_template(base, subpath, template_file)
  end
end

describe 'Skyed::Utils.read_key_file' do
  let(:file_path)  { '/home/user/.ssh/id_rsa' }
  let(:fd)         { double('File') }
  let(:fd_content) { 'ssh-rsa ASDASFQASDFGRTGVW' }
  before(:each) do
    expect(File)
      .to receive(:open)
      .with(file_path, 'rb')
      .and_return(fd)
    expect(fd)
      .to receive(:read)
      .and_return(fd_content)
  end
  it 'returns the content of the key file' do
    expect(Skyed::Utils.read_key_file(file_path))
      .to eq(fd_content)
  end
end
