# frozen_string_literal: true

RSpec.describe RecurringDocumentFetcher::ConfigField do
  it "sets defaults" do
    field = described_class.new(name: "username", label: "Username")
    expect(field.name).to eq("username")
    expect(field.label).to eq("Username")
    expect(field.type).to eq(:string)
    expect(field.required).to be true
    expect(field.secret).to be false
    expect(field.cli_flag).to eq("--username")
  end

  it "accepts overrides" do
    field = described_class.new(name: "password", label: "Password", type: :string, required: true, secret: true,
                                cli_flag: "--password")
    expect(field.name).to eq("password")
    expect(field.required).to be true
    expect(field.secret).to be true
    expect(field.cli_flag).to eq("--password")
  end

  it "allows optional fields" do
    field = described_class.new(name: "format", label: "Output format", required: false)
    expect(field.required).to be false
  end
end
