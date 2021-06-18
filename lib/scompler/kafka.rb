# frozen_string_literal: true

require 'delivery_boy'

require_relative 'kafka/topic'
require_relative 'kafka/base_producer'
require_relative 'kafka/default_producer'
require_relative 'kafka/topic_mapper'
require_relative 'kafka/sync_topics'
require_relative 'kafka/serialization/avro'
require_relative 'kafka/configuration'

module Scompler
  module Kafka
    class << self
      def configure(&block)
        block.arity.zero? ? instance_eval(&block) : yield(config)
        config.reload
      end

      def config
        @config ||= Kafka::Configuration.config.reload
      end
    end
  end
end
