# frozen_string_literal: true

module Scompler
  module Kafka
    class TopicMapper
      # @param topic [String, Symbol] The topic
      # @return [String, Symbol] topic as on input
      # @example
      #   incoming('uat.scompler.topic.created') #=> 'topic_created'
      def incoming(topic)
        topic.to_s.gsub(prefix, '').gsub('.', '_')
      end

      # @param topic [String, Symbol] The topic
      # @return [String, Symbol] topic as on input
      # @example
      #   outgoing('topic_created') #=> 'topic.created'
      def outgoing(topic)
        [prefix, topic.to_s.gsub('_', '.')].join
      end

      def schema_name_from_topic(topic)
        topic.to_s.split('_')[0...-1].join('_')
      end

      def prefix
        @prefix ||= [
          ENV['CLUSTER_NAME'],
          Scompler::Kafka.config.scope.to_s
        ].reject(&:blank?).join('.').concat('.')
      end
    end
  end
end
