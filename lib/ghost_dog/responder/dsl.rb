module GhostDog
  class Responder
    class DSL
      def to_responder
        raise "Incomplete ghost method - must specify matcher and responding_block" unless [@matcher, @responder].all?

        Responder.new(@matcher, @responder)
      end

      private

      def respond_with(&block)
        @responder = block
      end

      def match_with(matcher_as_arg = nil, &matcher_as_block)
        raise "Must specify either exactly one of a matcher instance or a matcher block" unless !!matcher_as_arg ^ block_given?

        matcher = matcher_as_block || matcher_as_arg

        @matcher =
          if matcher.respond_to? :matches
            matcher
          else
            Responder.const_get("#{matcher.class}Matcher").new(matcher)
          end
      end
    end
  end
end
