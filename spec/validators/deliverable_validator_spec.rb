# frozen_string_literal: true

RSpec.describe DeliverableValidator do
  let(:api_url) { 'https://api.truelist.io/api/v1/verify' }

  let(:valid_response) { { state: 'valid', sub_state: 'ok' }.to_json }
  let(:invalid_response) { { state: 'invalid', sub_state: 'failed_no_mailbox' }.to_json }
  let(:risky_response) { { state: 'risky', sub_state: 'accept_all' }.to_json }
  let(:unknown_response) { { state: 'unknown', sub_state: 'unknown' }.to_json }

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
      stub_request(:post, api_url).to_return(status: 200, body: valid_response)
      record = model_class.new(email: 'user@example.com')

      expect(record).to be_valid
    end

    it 'fails for an invalid email' do
      stub_request(:post, api_url).to_return(status: 200, body: invalid_response)
      record = model_class.new(email: 'bad@example.com')

      expect(record).not_to be_valid
      expect(record.errors[:email]).to be_present
    end

    it 'passes for a risky email when allow_risky is true (default)' do
      Truelist.configuration.allow_risky = true
      stub_request(:post, api_url).to_return(status: 200, body: risky_response)
      record = model_class.new(email: 'info@example.com')

      expect(record).to be_valid
    end

    it 'passes for a genuine unknown result from the API' do
      stub_request(:post, api_url).to_return(status: 200, body: unknown_response)
      record = model_class.new(email: 'user@example.com')

      expect(record).to be_valid
    end

    it 'passes for transient API errors (fail open)' do
      stub_request(:post, api_url).to_return(status: 500, body: 'Internal Server Error')
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

    it 'fails for a risky email' do
      stub_request(:post, api_url).to_return(status: 200, body: risky_response)
      record = strict_model_class.new(email: 'info@example.com')

      expect(record).not_to be_valid
    end

    it 'passes for a valid email' do
      stub_request(:post, api_url).to_return(status: 200, body: valid_response)
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
      stub_request(:post, api_url).to_return(status: 200, body: invalid_response)
      record = custom_message_model.new(email: 'bad@example.com')

      record.valid?
      expect(record.errors[:email]).to include('is not a deliverable email address')
    end
  end
end
