# frozen_string_literal: true

module RecurringDocumentFetcher
  ConfigField = Struct.new(
    :name, :label, :type, :required, :secret, :cli_flag,
    keyword_init: true
  ) do
    def initialize(**kwargs)
      kwargs[:type] ||= :string
      kwargs[:required] = true if kwargs[:required].nil?
      kwargs[:secret] = false if kwargs[:secret].nil?
      kwargs[:cli_flag] ||= "--#{kwargs[:name]}"
      super
    end
  end
end
