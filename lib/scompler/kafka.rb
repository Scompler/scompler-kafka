# frozen_string_literal: true

require 'delivery_boy'
require 'active_support/dependencies/autoload'
require 'active_support/logger'
require 'active_support/core_ext/module/delegation'

module Scompler
  module Kafka
    extend ActiveSupport::Autoload

    autoload :BaseProducer
    autoload :Configuration
    autoload :DefaultProducer
    autoload :Extensions
    autoload :Interchanger
    autoload :Serialization
    autoload :SyncTopics
    autoload :Topic
    autoload :TopicMapper

    EXTERNAL_IDX_HEADER = 'X-Scompler-External-Idx'

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
