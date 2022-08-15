# frozen_string_literal: true

require 'dry-configurable'

require_relative 'topic_mapper'
require_relative 'serialization/avro'
require_relative 'interchanger/base64'

module Scompler
  module Kafka
    class Configuration
      extend Dry::Configurable

      setting :serializer, default: -> { serializer_for(config.scope).serializer }
      setting :deserializer, default: -> { serializer_for(config.scope).deserializer }
      setting :topic_mapper, default: TopicMapper.new
      setting :interchanger, default: Interchanger::Base64.new
      setting :scope, default: :scompler
      setting :backend, default: :inline
      setting :serializers_namespace, default: 'Kafka'

      setting :kafka do
        setting :brokers, default: 'localhost:9092'
        setting :client_id, default: 'scompler'
        setting :log_level

        # Buffering
        setting :max_buffer_bytesize, default: 10_000_000
        setting :max_buffer_size, default: 1000
        setting :max_queue_size, default: 1000

        # Network timeouts
        setting :connect_timeout, default: 10
        setting :socket_timeout, default: 30

        # Delivery
        setting :ack_timeout, default: 5
        setting :delivery_interval, default: 10
        setting :delivery_threshold, default: 100
        setting :max_retries, default: 2
        setting :required_acks, default: -1
        setting :retry_backoff, default: 1
        setting :idempotent, default: false
        setting :transactional, default: false
        setting :transactional_timeout, default: 60

        # Compression
        setting :compression_threshold, default: 1
        setting :compression_codec

        # SSL authentication
        setting :ssl_ca_cert
        setting :ssl_ca_cert_file_path
        setting :ssl_client_cert
        setting :ssl_client_cert_key
        setting :ssl_client_cert_key_password
        setting :ssl_ca_certs_from_system, default: true
        setting :ssl_verify_hostname, default: true

        # SASL authentication
        setting :sasl_gssapi_principal
        setting :sasl_gssapi_keytab
        setting :sasl_plain_authzid, default: ''
        setting :sasl_plain_username
        setting :sasl_plain_password
        setting :sasl_scram_username
        setting :sasl_scram_password
        setting :sasl_scram_mechanism
        setting :sasl_over_ssl, default: true
      end

      class << self
        def config
          @config ||= super.extend(ConfigExtension)
        end

        def serializer_for(registry_name)
          @serializer_for ||=
            if defined?(Scompler::Avro)
              Serialization::Avro.new(registry_name)
            else
              Serialization::Base.new
            end
        end
      end

      module ConfigExtension
        def reload
          configure_dynamic_settings
          configure_delivery_boy
          self
        end

        def configure_delivery_boy
          kafka.to_h.each do |key, value|
            DeliveryBoy.config.set(key, value)
          end
        end

        def configure_dynamic_settings
          to_h.each do |key, value|
            next unless value.is_a?(Proc)

            self[key] = value.call
          end
        end
      end
    end
  end
end
