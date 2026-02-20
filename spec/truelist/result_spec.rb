# frozen_string_literal: true

RSpec.describe Truelist::Result do
  describe "#valid?" do
    it "returns true when state is valid" do
      result = described_class.new(email: "user@example.com", state: "valid")
      expect(result.valid?).to be(true)
    end

    it "returns true when state is risky and allow_risky is true" do
      Truelist.configuration.allow_risky = true
      result = described_class.new(email: "user@example.com", state: "risky")
      expect(result.valid?).to be(true)
    end

    it "returns false when state is risky and allow_risky is false" do
      Truelist.configuration.allow_risky = false
      result = described_class.new(email: "user@example.com", state: "risky")
      expect(result.valid?).to be(false)
    end

    it "returns false when state is invalid" do
      result = described_class.new(email: "bad@example.com", state: "invalid")
      expect(result.valid?).to be(false)
    end

    it "returns false when state is unknown" do
      result = described_class.new(email: "user@example.com", state: "unknown")
      expect(result.valid?).to be(false)
    end
  end

  describe "#invalid?" do
    it "returns true when state is invalid" do
      result = described_class.new(email: "bad@example.com", state: "invalid")
      expect(result.invalid?).to be(true)
    end

    it "returns false when state is valid" do
      result = described_class.new(email: "user@example.com", state: "valid")
      expect(result.invalid?).to be(false)
    end
  end

  describe "#risky?" do
    it "returns true when state is risky" do
      result = described_class.new(email: "user@example.com", state: "risky")
      expect(result.risky?).to be(true)
    end

    it "returns false when state is valid" do
      result = described_class.new(email: "user@example.com", state: "valid")
      expect(result.risky?).to be(false)
    end
  end

  describe "#unknown?" do
    it "returns true when state is unknown" do
      result = described_class.new(email: "user@example.com", state: "unknown")
      expect(result.unknown?).to be(true)
    end

    it "returns false when state is valid" do
      result = described_class.new(email: "user@example.com", state: "valid")
      expect(result.unknown?).to be(false)
    end
  end

  describe "attributes" do
    subject(:result) do
      described_class.new(
        email: "user@example.com",
        state: "valid",
        sub_state: "ok",
        suggestion: "user@gmail.com",
        free_email: true,
        role: false,
        disposable: true
      )
    end

    it "returns the email" do
      expect(result.email).to eq("user@example.com")
    end

    it "returns the state as a string" do
      expect(result.state).to eq("valid")
    end

    it "returns the sub_state as a string" do
      expect(result.sub_state).to eq("ok")
    end

    it "returns the suggestion" do
      expect(result.suggestion).to eq("user@gmail.com")
    end

    it "returns free_email?" do
      expect(result.free_email?).to be(true)
    end

    it "returns role?" do
      expect(result.role?).to be(false)
    end

    it "returns disposable?" do
      expect(result.disposable?).to be(true)
    end
  end

  describe "state coercion" do
    it "converts symbol states to strings" do
      result = described_class.new(email: "user@example.com", state: :valid, sub_state: :ok)
      expect(result.state).to eq("valid")
      expect(result.sub_state).to eq("ok")
    end
  end
end
