# frozen_string_literal: true

require_relative 'base'

module Scompler
  module Kafka
    module Serialization
      class Avro < Base
        attr_reader :registry_name

        def initialize(registry_name)
          super()
          @registry_name = registry_name
        end

        def serializer
          @serializer ||= Scompler::Avro::Serializer.new(avro: schema_store.as_avro)
        end

        def deserializer
          @deserializer ||= Scompler::Avro::Deserializer.new(avro: schema_store.as_avro)
        end

        protected

        def schema_store
          @schema_store ||= Scompler::Avro::SchemaStore.new(registry_name: registry_name)
        end
      end
    end
  end
end
