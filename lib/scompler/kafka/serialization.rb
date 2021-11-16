# frozen_string_literal: true

module Scompler
  module Kafka
    module Serialization
      extend ActiveSupport::Autoload

      autoload :Base
      autoload :Avro
    end
  end
end
