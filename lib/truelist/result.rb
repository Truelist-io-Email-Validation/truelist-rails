# frozen_string_literal: true

module Truelist
  class Result
    attr_reader :email, :state, :sub_state, :suggestion, :domain, :canonical,
                :mx_record, :first_name, :last_name, :verified_at, :error

    def initialize(email:, state:, sub_state: nil, suggestion: nil, domain: nil, canonical: nil,
                   mx_record: nil, first_name: nil, last_name: nil, verified_at: nil, error: false)
      @email = email
      @state = state.to_s
      @sub_state = sub_state&.to_s
      @suggestion = suggestion
      @domain = domain
      @canonical = canonical
      @mx_record = mx_record
      @first_name = first_name
      @last_name = last_name
      @verified_at = verified_at
      @error = error
    end

    def valid?
      state == 'ok' || (state == 'accept_all' && Truelist.configuration.allow_risky)
    end

    def invalid?
      state == 'email_invalid'
    end

    def accept_all?
      state == 'accept_all'
    end

    def unknown?
      state == 'unknown'
    end

    def disposable?
      sub_state == 'is_disposable'
    end

    def role?
      sub_state == 'is_role'
    end

    def error?
      @error
    end
  end
end
