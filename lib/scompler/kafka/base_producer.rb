# frozen_string_literal: true

module Scompler
  module Kafka
    class BaseProducer
      def initialize
        @messages = {}
      end

      def produce(_)
        raise NotImplementedError, 'Implement produce method in a subclass'
      end

      def produce_to(topic_name, data, options = {})
        topic = self.class.topics[topic_name]
        raise "Unknown #{topic_name} topic" if topic.blank?

        messages[topic_name] ||= []
        messages[topic_name] << [
          topic.serializer.call(data, **serializer_options_for(topic, options)),
          options.merge(topic: topic_name)
        ]
      end

      def call(*options)
        produce(*options)
        deliver!
      end

      protected

      attr_reader :messages

      def serializer_options_for(topic, options)
        topic_options = topic.options

        schema_name = options[:schema_name] ||
                      topic_options[:schema_name] ||
                      topic_mapper.schema_name_from_topic(topic.name)
        version_number = options[:version_number] || topic_options[:version_number]

        {
          schema_name: schema_name,
          version_number: version_number
        }
      end

      def deliver!
        messages.each_value do |topic_messages|
          topic_messages.each do |data, options|
            mapped_topic = topic_mapper.outgoing(options[:topic])
            external_options = options.merge(topic: mapped_topic)

            method_name = deliver_method_name_for(options)
            DeliveryBoy.send(method_name, data, external_options)
          end
        end
      end

      def deliver_method_name_for(options)
        if self.class.topics[options[:topic]].async?
          :deliver_async
        else
          :deliver
        end
      end

      def topic_mapper
        Scompler::Kafka.config.topic_mapper
      end

      class << self
        def topic(name, options = {})
          topics[name] = Scompler::Kafka::Topic.new(name, options)
        end

        def topics
          @topics ||= ActiveSupport::HashWithIndifferentAccess.new
        end

        def default_producer(options = {})
          Scompler::Kafka::DefaultProducer.new(self, options).setup
        end

        def call(*options)
          new.call(*options)
        end
      end
    end
  end
end
