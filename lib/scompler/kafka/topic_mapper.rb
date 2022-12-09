# frozen_string_literal: true

module Scompler
  module Kafka
    class TopicMapper
      # @param topic [String, Symbol] The topic
      # @return [String, Symbol] topic as on input
      # @example
      #   incoming('uat_scompler_topic_created') #=> 'topic_created'
      def incoming(topic)
        topic.to_s.gsub(prefix, '')
      end

      # @param topic [String, Symbol] The topic
      # @return [String, Symbol] topic as on input with prefix
      # @example
      #   outgoing('topic_created') #=> 'uat_scompler_topic_created'
      def outgoing(topic)
        [prefix, topic.to_s].join
      end

      def schema_name_from_topic(topic)
        topic.to_s.split('_')[0...-1].join('_')
      end

      def prefix
        @prefix ||= [
          ENV['CLUSTER_NAME'],
          Scompler::Kafka.config.scope.to_s
        ].reject(&:blank?).join('_').concat('_')
      end
    end
  end
end
