module GhostDog
  class Responder
    class ProcMatcher < Struct.new(:block)
      def matches(receiver, method_name)
        receiver.instance_exec(method_name, &block)
      end
    end
  end
end
