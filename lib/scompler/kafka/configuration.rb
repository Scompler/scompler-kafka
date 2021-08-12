# frozen_string_literal: true

require 'dry-configurable'

module Scompler
  module Kafka
    class Configuration
      extend Dry::Configurable

      setting :serializer, -> { serializer_for(config.scope).serializer }
      setting :deserializer, -> { serializer_for(config.scope).deserializer }
      setting :topic_mapper, Scompler::Kafka::TopicMapper.new
      setting :scope, :scompler
      setting :backend, :inline
      setting :serializers_namespace, 'Kafka'
      setting :environment, 'production'
      setting :kafka do
        setting :brokers, 'localhost:9092'
        setting :client_id, 'scompler'
        setting :log_level

        # Buffering
        setting :max_buffer_bytesize, 10_000_000
        setting :max_buffer_size, 1000
        setting :max_queue_size, 1000

        # Network timeouts
        setting :connect_timeout, 10
        setting :socket_timeout, 30

        # Delivery
        setting :ack_timeout, 5
        setting :delivery_interval, 10
        setting :delivery_threshold, 100
        setting :max_retries, 2
        setting :required_acks, -1
        setting :retry_backoff, 1
        setting :idempotent, false
        setting :transactional, false
        setting :transactional_timeout, 60

        # Compression
        setting :compression_threshold, 1
        setting :compression_codec

        # SSL authentication
        setting :ssl_ca_cert
        setting :ssl_ca_cert_file_path
        setting :ssl_client_cert
        setting :ssl_client_cert_key
        setting :ssl_client_cert_key_password
        setting :ssl_ca_certs_from_system, true
        setting :ssl_verify_hostname, true

        # SASL authentication
        setting :sasl_gssapi_principal
        setting :sasl_gssapi_keytab
        setting :sasl_plain_authzid, ''
        setting :sasl_plain_username
        setting :sasl_plain_password
        setting :sasl_scram_username
        setting :sasl_scram_password
        setting :sasl_scram_mechanism
        setting :sasl_over_ssl, true
      end

      class << self
        def config
          @config ||= super.extend(ConfigExtension)
        end

        def serializer_for(registry_name)
          @serializer_for ||=
            if defined?(Scompler::Avro)
              Scompler::Kafka::Serialization::Avro.new(registry_name)
            else
              Scompler::Kafka::Serialization::Base.new
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
