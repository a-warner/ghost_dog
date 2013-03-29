require 'ghost_dog/version'
require 'ghost_dog/responder'
require 'delegate'

module GhostDog
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def respond_to?(method, include_private = false)
      super || !!responding_ghost_method(method.to_s)
    end

    private

    def _ghost_methods
      _klass_where_ghost_method_definitions_are.send(:_ghost_method_definitions)
    end

    def _klass_where_ghost_method_definitions_are
      if self.class == Class
        self.singleton_class
      else
        self.class
      end
    end

    def responding_ghost_method(method)
      @_considered_methods ||= []
      return if @_considered_methods.include?(method)

      @_considered_methods << method

      _ghost_methods.detect do |matcher|
        matcher.matches?(self, method)
      end
    ensure
      @_considered_methods = []
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
      _setup_ghost_dog_singleton_class_inheritance(child)
      super
    end

    def _setup_ghost_dog_singleton_class_inheritance(child)
      if singleton_class.respond_to?(:_setup_ghost_dog_inheritance, :include_private)
        singleton_class.send(:_setup_ghost_dog_inheritance, child.singleton_class)
      end
    end
  end

  module ClassMethods
    protected

    def ghost_method(matcher = nil, &block)
      _ghost_method_definitions << Responder.from(matcher, block)
    end

    private

    def _ghost_method_definitions
      @_ghost_methods ||= []
    end

    def inherited(child)
      _setup_ghost_dog_inheritance(child)
      super
    end

    def _setup_ghost_dog_inheritance(child)
      child.instance_variable_set('@_ghost_methods', _ghost_method_definitions)
    end
  end
end
