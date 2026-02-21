# frozen_string_literal: true

RSpec.describe DeliverableValidator do
  let(:api_url) { 'https://api.truelist.io/api/v1/verify_inline' }

  let(:valid_response) do
    { emails: [{ address: 'user@example.com', email_state: 'ok', email_sub_state: 'email_ok' }] }.to_json
  end

  let(:invalid_response) do
    { emails: [{ address: 'bad@example.com', email_state: 'email_invalid',
                 email_sub_state: 'failed_smtp_check' }] }.to_json
  end

  let(:accept_all_response) do
    { emails: [{ address: 'info@example.com', email_state: 'accept_all',
                 email_sub_state: 'email_ok' }] }.to_json
  end

  let(:unknown_response) do
    { emails: [{ address: 'user@example.com', email_state: 'unknown',
                 email_sub_state: 'unknown_error' }] }.to_json
  end

  # Minimal test model using ActiveModel
  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :email

      def self.name
        'TestModel'
      end
    end
  end

  describe 'validates :email, deliverable: true' do
    before do
      model_class.validates :email, deliverable: true
    end

    it 'passes for a valid email' do
      stub_request(:post, api_url)
        .with(query: { email: 'user@example.com' })
        .to_return(status: 200, body: valid_response)
      record = model_class.new(email: 'user@example.com')

      expect(record).to be_valid
    end

    it 'fails for an invalid email' do
      stub_request(:post, api_url)
        .with(query: { email: 'bad@example.com' })
        .to_return(status: 200, body: invalid_response)
      record = model_class.new(email: 'bad@example.com')

      expect(record).not_to be_valid
      expect(record.errors[:email]).to be_present
    end

    it 'passes for an accept_all email when allow_risky is true (default)' do
      Truelist.configuration.allow_risky = true
      stub_request(:post, api_url)
        .with(query: { email: 'info@example.com' })
        .to_return(status: 200, body: accept_all_response)
      record = model_class.new(email: 'info@example.com')

      expect(record).to be_valid
    end

    it 'passes for a genuine unknown result from the API' do
      stub_request(:post, api_url)
        .with(query: { email: 'user@example.com' })
        .to_return(status: 200, body: unknown_response)
      record = model_class.new(email: 'user@example.com')

      expect(record).to be_valid
    end

    it 'passes for transient API errors (fail open)' do
      stub_request(:post, api_url)
        .with(query: { email: 'user@example.com' })
        .to_return(status: 500, body: 'Internal Server Error')
      record = model_class.new(email: 'user@example.com')

      expect(record).to be_valid
    end

    it 'skips validation when email is blank' do
      record = model_class.new(email: '')

      expect(record).to be_valid
    end

    it 'skips validation when email is nil' do
      record = model_class.new(email: nil)

      expect(record).to be_valid
    end
  end

  describe 'with allow_risky: false option' do
    let(:strict_model_class) do
      klass = Class.new do
        include ActiveModel::Model
        include ActiveModel::Validations

        attr_accessor :email

        def self.name
          'StrictModel'
        end
      end
      klass.validates :email, deliverable: { allow_risky: false }
      klass
    end

    it 'fails for an accept_all email' do
      stub_request(:post, api_url)
        .with(query: { email: 'info@example.com' })
        .to_return(status: 200, body: accept_all_response)
      record = strict_model_class.new(email: 'info@example.com')

      expect(record).not_to be_valid
    end

    it 'passes for a valid email' do
      stub_request(:post, api_url)
        .with(query: { email: 'user@example.com' })
        .to_return(status: 200, body: valid_response)
      record = strict_model_class.new(email: 'user@example.com')

      expect(record).to be_valid
    end
  end

  describe 'with custom message' do
    let(:custom_message_model) do
      klass = Class.new do
        include ActiveModel::Model
        include ActiveModel::Validations

        attr_accessor :email

        def self.name
          'CustomMessageModel'
        end
      end
      klass.validates :email, deliverable: { message: 'is not a deliverable email address' }
      klass
    end

    it 'uses the custom error message' do
      stub_request(:post, api_url)
        .with(query: { email: 'bad@example.com' })
        .to_return(status: 200, body: invalid_response)
      record = custom_message_model.new(email: 'bad@example.com')

      record.valid?
      expect(record.errors[:email]).to include('is not a deliverable email address')
    end
  end
end
