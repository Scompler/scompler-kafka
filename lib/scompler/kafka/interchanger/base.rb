# frozen_string_literal: true

module Scompler
  module Kafka
    module Interchanger
      class Base
        # @param params_batch [Karafka::Params::ParamsBatch] Karafka params batch object
        # @return [Array<Hash>] Array with hash built out of params data
        def encode(params_batch)
          params_batch.map do |param|
            {
              raw_payload: param.raw_payload,
              metadata: param.metadata.except(:deserializer)
            }
          end
        end

        # @param params_batch [Array<Hash>] Sidekiq params that are now an array
        # @return [Array<Hash>] exactly what we've fetched from Sidekiq
        def decode(params_batch)
          params_batch
        end
      end
    end
  end
end
