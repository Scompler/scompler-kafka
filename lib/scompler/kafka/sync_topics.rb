# frozen_string_literal: true

module Scompler
  module Kafka
    class SyncTopics
      TOPIC_OPTIONS = %i[num_partitions replication_factor timeout config].freeze

      class << self
        def call(classes)
          new(classes).call
        end
      end

      def initialize(classes)
        @classes = Array(classes)
        @app_topics = []
      end

      def sync
        p "Going to sync #{classes.size} producers"
        classes.each do |klass|
          sync_topics_for(klass)
        end
      end

      alias call sync

      def clear
        removed_topics = kafka_topics - app_topics
        return if removed_topics.blank?

        p "Found #{removed_topics.size} removed topics"
        removed_topics.each do |name|
          p "Remove #{name} topic"
          kafka.delete_topic(name)
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

      def sync_topics_for(klass)
        p "Going to sync #{klass} topics"
        klass.topics.each do |_, topic|
          name, options = topic.name, topic.options.slice(*TOPIC_OPTIONS)

          full_name = topic_mapper.outgoing(name)
          @app_topics << full_name

          create_or_alter_topic(full_name, options)
        end
      end

      def create_or_alter_topic(name, options = {})
        if kafka_topics.include?(name)
          return if options.blank?

          alter_partitions_for(name, options.slice(:num_partitions, :timeout))
          alter_config_for(name, options.fetch(:config))
        else
          create_topic(name, options)
        end
      end

      def create_topic(name, options)
        p "Create #{name} topic with params #{options}"
        kafka.create_topic(name, options)
      end

      def alter_config_for(name, config = {})
        return if config.blank?

        existing_config = kafka.describe_topic(name, config.keys)
        return if existing_config == config

        p "Alter #{name} topic config with params #{config}"
        kafka.alter_topic(name, config)
      end

      def alter_partitions_for(name, num_partitions:, timeout: 30)
        return if num_partitions.nil? || (num_partitions == kafka.partitions_for(name))

        p "Alter #{name} topic with #{num_partitions} partitions"
        kafka.create_partitions_for(name, num_partitions: num_partitions, timeout: timeout)
      end
    end
  end
end
