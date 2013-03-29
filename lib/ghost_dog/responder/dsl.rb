module GhostDog
  class Responder
    class DSL
      [:matcher, :responder].each do |dsl_method|
        define_method(dsl_method) do |&block|
          instance_variable_set("@#{dsl_method}", block)
        end
        private dsl_method
      end

      def to_responder
        raise "Incomplete ghost method - must specify matcher and responding_block" unless [@matcher, @responder].all?

        Responder.new(@matcher, @responder)
      end
    end
  end
end
