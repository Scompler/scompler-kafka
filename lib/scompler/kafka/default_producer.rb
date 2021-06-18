# frozen_string_literal: true

module Scompler
  module Kafka
    class DefaultProducer
      PRODUCER_OPTIONS = %i[serializer resource event].freeze

      attr_reader :context, :options

      def initialize(context, options)
        @context = context
        @options = options
      end

      def setup
        resource_class = self.resource_class
        serializer_class = self.serializer_class
        topic_name = self.topic_name

        external_options = options.except(*PRODUCER_OPTIONS)
        context.topic topic_name, external_options

        context.redefine_method :produce do |resource_id|
          resource = resource_class.find_by(external_idx: resource_id)
          return if resource.blank?

          serializer = serializer_class.new(resource)
          produce_to topic_name, serializer.as_json
        end
      end

      protected

      def version
        @version ||= options.fetch(:version, 1)
      end

      def serializer
        @serializer ||= options.fetch(:serializer) do
          namespaces = [Scompler::Kafka.config.serializers_namespace, "V#{version}"]
          serializer_class_names.
            lazy.map { |name| [*namespaces, "#{name}Serializer"].join('::').safe_constantize }.
            find(&:itself)
        end
      end

      def serializer_class_names
        names = [resource_name]
        names.unshift(resource_name.demodulize) if options.key?(:resource)
        names
      end

      def serializer_class
        if serializer.is_a?(String)
          serializer.constantize
        else
          serializer
        end
      end

      def serializer_base_class
        if options.key?(:resource)
          resource_name.demodulize
        else
          resource_name
        end
      end

      def topic_name
        @topic_name ||= options.fetch(:topic) do
          [schema_name, event_name].join('_')
        end
      end

      def schema_name
        @schema_name ||= options.fetch(:schema_name) do
          context.to_s.deconstantize.split('::').reverse.join.underscore
        end
      end

      def resource
        @resource ||= options.fetch(:resource) do
          context.to_s.deconstantize
        end
      end

      def resource_name
        if resource.is_a?(String)
          resource
        else
          resource.to_s
        end
      end

      def resource_class
        if resource.is_a?(String)
          resource.constantize
        else
          resource
        end
      end

      def event_name
        @event_name ||= options.fetch(:event) do
          context.to_s.demodulize.gsub(/Producer$/, '').underscore
        end
      end
    end
  end
end
