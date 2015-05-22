require 'spec_helper'

describe 'Skyed::Settings.current_stack?' do
  let(:stack_id)   { '12345678-1234-1234-1234-123456789012' }
  context 'when not setup' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(true)
    end
    it 'stack is not current' do
      expect(Skyed::Settings.current_stack?(stack_id))
        .to eq(false)
    end
  end
  context 'when setup' do
    before(:each) do
      expect(Skyed::Settings)
        .to receive(:empty?)
        .and_return(false)
    end
    context 'and different stack_id' do
      before(:each) do
        expect(Skyed::Settings)
          .to receive(:stack_id)
          .and_return('87654321-4321-4321-4321-210987654321')
      end
      it 'stack is not current' do
        expect(Skyed::Settings.current_stack?(stack_id))
          .to eq(false)
      end
    end
    context 'and same stack_id' do
      before(:each) do
        expect(Skyed::Settings)
          .to receive(:stack_id)
          .and_return(stack_id)
      end
      it 'stack is current' do
        expect(Skyed::Settings.current_stack?(stack_id))
          .to eq(true)
      end
    end
  end
end
