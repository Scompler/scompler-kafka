# frozen_string_literal: true

module Scompler
  module Kafka
    class SyncTopics
      def initialize(classes)
        @classes = Array(classes)
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
        removed_topics.each do |name|
          p "Remove #{name} topic"
          kafka.delete_topic(name)
        end
      end

      def sync
        p "Going to sync #{classes.size} producers"
        classes.each do |klass|
          sync_topics_for(klass)
        end
      end

      def sync_topics_for(klass)
        p "Going to sync #{klass} topics"
        klass.topics.each do |name, topic|
          options = topic.options

          full_name = topic_mapper.outgoing(name)
          @app_topics << full_name

          create_or_alter_topic(full_name, options)
        end
      end

      def create_or_alter_topic(name, options = {})
        if kafka_topics.include?(name)
          return if options.blank?

          alter_partitions_for(name, options.slice(:num_partitions, :timeout))
          alter_configs_for(name, options.fetch(:config))
        else
          create_topic(name, options)
        end
      end

      def create_topic(name, options)
        p "Create #{name} topic with params #{options}"
        kafka.create_topic(name, options)
      end

      def alter_configs_for(name, configs = {})
        return if configs.blank?

        existing_configs = kafka.describe_topic(name, configs.keys)
        return if existing_configs == configs

        p "Alter #{name} topic configs with params #{configs}"
        kafka.alter_topic(name, configs)
      end

      def alter_partitions_for(name, num_partitions:, timeout: 30)
        return if num_partitions.nil? || (num_partitions == kafka.partitions_for(name))

        p "Alter #{name} topic with #{num_partitions} partitions"
        kafka.create_partitions_for(name, num_partitions: num_partitions, timeout: timeout)
      end
    end
  end
end
