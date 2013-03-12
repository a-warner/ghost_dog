require "ghost_dog/version"

module GhostDog
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    def base._ghost_methods
      @_ghost_methods ||= []
    end
  end

  class Responder
    attr_reader :matcher, :responding_block
    def initialize(matcher, &responding_block)
      @matcher, @responding_block = matcher, responding_block
    end

    def matches?(method)
      matcher.match(method)
    end

    def call(receiver, method)
      matches = matcher.match(method).to_a.drop(1)
      respond_with = self.responding_block

      receiver.class.class_eval do
        define_method(method) do |*args, &block|
          instance_exec(*(matches + args).flatten, &respond_with)
        end
      end
    end
  end

  module InstanceMethods
    def respond_to?(method, include_private = false)
      super || !!responding_ghost_method(method.to_s)
    end

    private

    def _ghost_methods
      self.class._ghost_methods
    end

    def responding_ghost_method(method)
      _ghost_methods.detect do |matcher|
        matcher.matches?(method)
      end
    end

    def method_missing(method, *args, &block)
      if matcher = responding_ghost_method(method.to_s)
        matcher.call(self, method.to_s)
        send(method, *args, &block)
      else
        super
      end
    end
  end

  module ClassMethods
    def ghost_method(matcher, &block)
      _ghost_methods << Responder.new(matcher, &block)
    end
  end
end
