require 'ghost_dog/version'
require 'delegate'

module GhostDog
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  class Responder
    class RegexpMatcher < Struct.new(:regexp)
      def matches(receiver, method_name)
        if match = regexp.match(method_name)
          match.to_a.drop(1)
        end
      end
    end

    class ProcMatcher < Struct.new(:block)
      def matches(receiver, method_name)
        receiver.instance_exec(method_name, &block)
      end
    end

    class DSL
      [:matcher, :responder].each do |dsl_method|
        define_method(dsl_method) do |&block|
          instance_variable_set("@#{dsl_method}", block)
        end
      end

      def to_responder
        raise "Incomplete ghost method - must specify matcher and responding_block" unless [@matcher, @responder].all?

        Responder.new(@matcher, @responder)
      end
    end

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

  module InstanceMethods
    def respond_to?(method, include_private = false)
      super || !!responding_ghost_method(method.to_s)
    end

    private

    def _ghost_methods
      _klass_where_ghost_method_definitions_are._ghost_method_definitions
    end

    def _klass_where_ghost_method_definitions_are
      if self.class == Class
        self.singleton_class
      else
        self.class
      end
    end

    def responding_ghost_method(method)
      _ghost_methods.detect do |matcher|
        matcher.matches?(self, method)
      end
    end

    def method_missing(method, *args, &block)
      if matcher = responding_ghost_method(method.to_s)
        matcher.call(self, _klass_where_ghost_method_definitions_are, method.to_s)
        send(method, *args, &block)
      else
        super
      end
    end

    def inherited(child)
      if singleton_class.respond_to?(:_setup_ghost_dog_inheritance)
        singleton_class._setup_ghost_dog_inheritance(child.singleton_class)
      end
      super
    end
  end

  module ClassMethods
    def ghost_method(matcher = nil, &block)
      _ghost_method_definitions << Responder.from(matcher, block)
    end

    def _ghost_method_definitions
      @_ghost_methods ||= []
    end

    def _setup_ghost_dog_inheritance(child)
      child.instance_variable_set('@_ghost_methods', _ghost_method_definitions)
    end

    private

    def inherited(child)
      _setup_ghost_dog_inheritance(child)
      super
    end
  end
end
