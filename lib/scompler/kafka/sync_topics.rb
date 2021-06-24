# frozen_string_literal: true

module Scompler
  module Kafka
    class SyncTopics
      def initialize(classes)
        @classes = classes
        @app_topics = []
      end

      def call
        sync
        clean
      end

      class << self
        def call(classes)
          new(classes).call
        end
      end

      protected

      attr_reader :app_topics, :classes

      def kafka
        @kafka ||= ::Kafka.new(ENV['KAFKA_BROKER_HOSTS'], ssl_ca_certs_from_system: true)
      end

      def kafka_topics
        @kafka_topics ||= kafka.topics.keep_if { |name| name.start_with?(topic_mapper.prefix) }
      end

      def topic_mapper
        Scompler::Kafka.config.topic_mapper
      end

      def clean
        removed_topics = kafka_topics - app_topics
        return if removed_topics.blank?

        p "Found #{removed_topics.size} removed topics"
        removed_topics.each do |topic_name|
          p "Remove #{topic_name} topic"
          kafka.delete_topic(topic_name)
        end
      end

      def sync
        p "Going to sync #{classes.size} topics"
        classes.each do |klass|
          klass.topics.each do |topic_name, _|
            # TODO: Add topic options updating
            topic_name = topic_mapper.outgoing(topic_name)
            @app_topics << topic_name
            next if kafka_topics.include?(topic_name)

            p "Create #{topic_name} topic"
            kafka.create_topic(topic_name)
          end
        end
      end
    end
  end
end
