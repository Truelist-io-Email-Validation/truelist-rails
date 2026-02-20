# frozen_string_literal: true

RSpec.describe Truelist::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "has nil api_key by default" do
      allow(ENV).to receive(:[]).with("TRUELIST_API_KEY").and_return(nil)
      fresh_config = described_class.new
      expect(fresh_config.api_key).to be_nil
    end

    it "has the correct base_url" do
      expect(config.base_url).to eq("https://api.truelist.io")
    end

    it "has a 10-second timeout" do
      expect(config.timeout).to eq(10)
    end

    it "does not raise on error by default" do
      expect(config.raise_on_error).to be(false)
    end

    it "allows risky emails by default" do
      expect(config.allow_risky).to be(true)
    end

    it "has no cache store by default" do
      expect(config.cache_store).to be_nil
    end

    it "has a 1-hour cache TTL" do
      expect(config.cache_ttl).to eq(3600)
    end
  end

  describe "#api_key!" do
    it "returns the api_key when set" do
      config.api_key = "my_key"
      expect(config.api_key!).to eq("my_key")
    end

    it "raises Truelist::Error when api_key is nil" do
      config.api_key = nil
      expect { config.api_key! }.to raise_error(Truelist::Error, /API key is not configured/)
    end
  end

  describe "Truelist.configure" do
    it "yields the configuration" do
      Truelist.configure do |c|
        c.api_key = "configured_key"
        c.timeout = 30
      end

      expect(Truelist.configuration.api_key).to eq("configured_key")
      expect(Truelist.configuration.timeout).to eq(30)
    end
  end

  describe "Truelist.reset_configuration!" do
    it "resets to defaults" do
      Truelist.configure { |c| c.timeout = 99 }
      Truelist.reset_configuration!
      expect(Truelist.configuration.timeout).to eq(10)
    end
  end
end
