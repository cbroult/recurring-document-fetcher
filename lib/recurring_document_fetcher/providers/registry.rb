# frozen_string_literal: true

module RecurringDocumentFetcher
  module Providers
    class Registry
      class << self
        def register(type, klass)
          registry[type.to_s] = klass
        end

        def resolve(type)
          registry.fetch(type.to_s) do
            raise ProviderError, "Unknown provider type: #{type}. Available types: #{registered_types.join(", ")}"
          end
        end

        def registered_types
          registry.keys.sort
        end

        def clear
          registry.clear
        end

        private

        def registry
          @registry ||= {}
        end
      end
    end
  end
end
