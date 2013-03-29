module GhostDog
  class Responder
    class RegexpMatcher < Struct.new(:regexp)
      def matches(receiver, method_name)
        if match = regexp.match(method_name)
          match.to_a.drop(1)
        end
      end
    end
  end
end
