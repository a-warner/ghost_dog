require 'ghost_dog/responder/proc_matcher'
require 'ghost_dog/responder/regexp_matcher'
require 'ghost_dog/responder/dsl'

module GhostDog
  class Responder
    attr_reader :matcher, :responding_block
    def initialize(matcher, responding_block)
      @matcher = self.class.const_get("#{matcher.class}Matcher").new(matcher)
      @responding_block = responding_block
    end

    def matches(receiver, method)
      matcher.matches(receiver, method)
    end
    alias_method :matches?, :matches

    def call(instance, klass, method)
      match_result = matches(instance, method)

      klass.class_exec(responding_block) do |respond_with|
        define_method(method) do |*args, &block|
          instance_exec(*(match_result + args).flatten, &respond_with)
        end
      end
    end

    def self.from(matcher, block)
      if matcher.nil?
        from_dsl(block)
      else
        new(matcher, block)
      end
    end

    def self.from_dsl(block)
      Responder::DSL.new.tap do |dsl|
        dsl.instance_eval(&block)
      end.to_responder
    end
  end
end
