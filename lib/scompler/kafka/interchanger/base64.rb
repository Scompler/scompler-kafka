# frozen_string_literal: true

module Scompler
  module Kafka
    module Interchanger
      class Base64 < Base
        def encode(params_batch)
          Base64.encode64(Marshal.dump(super))
        end

        def decode(params_string)
          Marshal.load(Base64.decode64(super))
        end
      end
    end
  end
end
