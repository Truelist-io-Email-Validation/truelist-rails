# frozen_string_literal: true

RSpec.describe Truelist::Result do
  describe '#valid?' do
    it 'returns true when state is ok' do
      result = described_class.new(email: 'user@example.com', state: 'ok')
      expect(result.valid?).to be(true)
    end

    it 'returns true when state is accept_all and allow_risky is true' do
      Truelist.configuration.allow_risky = true
      result = described_class.new(email: 'user@example.com', state: 'accept_all')
      expect(result.valid?).to be(true)
    end

    it 'returns false when state is accept_all and allow_risky is false' do
      Truelist.configuration.allow_risky = false
      result = described_class.new(email: 'user@example.com', state: 'accept_all')
      expect(result.valid?).to be(false)
    end

    it 'returns false when state is email_invalid' do
      result = described_class.new(email: 'bad@example.com', state: 'email_invalid')
      expect(result.valid?).to be(false)
    end

    it 'returns false when state is unknown' do
      result = described_class.new(email: 'user@example.com', state: 'unknown')
      expect(result.valid?).to be(false)
    end
  end

  describe '#invalid?' do
    it 'returns true when state is email_invalid' do
      result = described_class.new(email: 'bad@example.com', state: 'email_invalid')
      expect(result.invalid?).to be(true)
    end

    it 'returns false when state is ok' do
      result = described_class.new(email: 'user@example.com', state: 'ok')
      expect(result.invalid?).to be(false)
    end
  end

  describe '#accept_all?' do
    it 'returns true when state is accept_all' do
      result = described_class.new(email: 'user@example.com', state: 'accept_all')
      expect(result.accept_all?).to be(true)
    end

    it 'returns false when state is ok' do
      result = described_class.new(email: 'user@example.com', state: 'ok')
      expect(result.accept_all?).to be(false)
    end
  end

  describe '#unknown?' do
    it 'returns true when state is unknown' do
      result = described_class.new(email: 'user@example.com', state: 'unknown')
      expect(result.unknown?).to be(true)
    end

    it 'returns false when state is ok' do
      result = described_class.new(email: 'user@example.com', state: 'ok')
      expect(result.unknown?).to be(false)
    end
  end

  describe '#disposable?' do
    it 'returns true when sub_state is is_disposable' do
      result = described_class.new(email: 'user@example.com', state: 'email_invalid', sub_state: 'is_disposable')
      expect(result.disposable?).to be(true)
    end

    it 'returns false when sub_state is something else' do
      result = described_class.new(email: 'user@example.com', state: 'ok', sub_state: 'email_ok')
      expect(result.disposable?).to be(false)
    end
  end

  describe '#role?' do
    it 'returns true when sub_state is is_role' do
      result = described_class.new(email: 'info@example.com', state: 'email_invalid', sub_state: 'is_role')
      expect(result.role?).to be(true)
    end

    it 'returns false when sub_state is something else' do
      result = described_class.new(email: 'user@example.com', state: 'ok', sub_state: 'email_ok')
      expect(result.role?).to be(false)
    end
  end

  describe 'attributes' do
    subject(:result) do
      described_class.new(
        email: 'user@example.com',
        state: 'ok',
        sub_state: 'email_ok',
        suggestion: 'user@gmail.com',
        domain: 'example.com',
        canonical: 'user',
        mx_record: 'mx.example.com',
        first_name: 'John',
        last_name: 'Doe',
        verified_at: '2026-02-21T10:00:00.000Z'
      )
    end

    it 'returns the email' do
      expect(result.email).to eq('user@example.com')
    end

    it 'returns the state as a string' do
      expect(result.state).to eq('ok')
    end

    it 'returns the sub_state as a string' do
      expect(result.sub_state).to eq('email_ok')
    end

    it 'returns the suggestion' do
      expect(result.suggestion).to eq('user@gmail.com')
    end

    it 'returns the domain' do
      expect(result.domain).to eq('example.com')
    end

    it 'returns the canonical' do
      expect(result.canonical).to eq('user')
    end

    it 'returns the mx_record' do
      expect(result.mx_record).to eq('mx.example.com')
    end

    it 'returns the first_name' do
      expect(result.first_name).to eq('John')
    end

    it 'returns the last_name' do
      expect(result.last_name).to eq('Doe')
    end

    it 'returns the verified_at' do
      expect(result.verified_at).to eq('2026-02-21T10:00:00.000Z')
    end
  end

  describe '#error?' do
    it 'returns true when error flag is set' do
      result = described_class.new(email: 'user@example.com', state: 'unknown', error: true)
      expect(result.error?).to be(true)
    end

    it 'returns false by default' do
      result = described_class.new(email: 'user@example.com', state: 'unknown')
      expect(result.error?).to be(false)
    end
  end

  describe 'state coercion' do
    it 'converts symbol states to strings' do
      result = described_class.new(email: 'user@example.com', state: :ok, sub_state: :email_ok)
      expect(result.state).to eq('ok')
      expect(result.sub_state).to eq('email_ok')
    end
  end
end
