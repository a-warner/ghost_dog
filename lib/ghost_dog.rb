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
      if self.class.is_a?(Class)
        singleton_class.extend(ClassMethods) unless singleton_class.is_a?(ClassMethods)

        singleton_class
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
        matcher.call(self, _klass_where_ghost_method_definitions_are, method.to_s, args, block)
      else
        super
      end
    end
  end

  module ClassMethods
    protected

    def ghost_method(matcher = nil, options = {}, &block)
      _ghost_method_definitions << Responder.from(matcher, options, block)
    end

    private

    def _ghost_method_definitions
      @_ghost_methods ||= [].tap do |defs|
        klasses_that_might_have_ghost_methods = []
        klasses_that_might_have_ghost_methods << superclass if defined?(superclass)
        klasses_that_might_have_ghost_methods.concat(included_modules)

        klasses_that_might_have_ghost_methods.select { |k| k.respond_to?(:_ghost_method_definitions, :include_private) }.each do |k|
          defs.concat(k.send(:_ghost_method_definitions).dup)
        end
      end
    end
  end
end
