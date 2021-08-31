# frozen_string_literal: true

module Scompler
  module Kafka
    module Extensions
      module TopicAttributes
        def interchanger
          @interchanger ||= Interchanger::Base64.new
        end
      end
    end
  end
end
