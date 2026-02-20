# frozen_string_literal: true

module Truelist
  class Result
    attr_reader :email, :state, :sub_state, :suggestion, :free_email, :role, :disposable

    def initialize(email:, state:, sub_state: nil, suggestion: nil, free_email: false, role: false, disposable: false)
      @email = email
      @state = state.to_s
      @sub_state = sub_state&.to_s
      @suggestion = suggestion
      @free_email = free_email
      @role = role
      @disposable = disposable
    end

    def valid?
      state == "valid" || (state == "risky" && Truelist.configuration.allow_risky)
    end

    def invalid?
      state == "invalid"
    end

    def risky?
      state == "risky"
    end

    def unknown?
      state == "unknown"
    end

    def free_email?
      @free_email
    end

    def role?
      @role
    end

    def disposable?
      @disposable
    end
  end
end
