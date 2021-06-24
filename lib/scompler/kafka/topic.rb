# frozen_string_literal: true

module Scompler
  module Kafka
    class Topic
      attr_reader :name, :options

      def initialize(name, options = {})
        @name = name.to_s
        @options = options
      end

      def serializer
        @serializer ||= options.fetch(:serializer) { Scompler::Kafka.config.serializer }
      end

      def async?
        options.key?(:async) ? options[:async] : false
      end
    end
  end
end
