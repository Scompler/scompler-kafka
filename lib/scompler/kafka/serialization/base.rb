# frozen_string_literal: true

module Scompler
  module Kafka
    module Serialization
      class Base
        def serializer; end

        def deserializer; end
      end
    end
  end
end
