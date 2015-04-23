require 'spec_helper'
require 'skyed'

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
