require 'ghost_dog/responder/proc_matcher'
require 'ghost_dog/responder/regexp_matcher'
require 'ghost_dog/responder/dsl'

module GhostDog
  class Responder
    attr_reader :matcher, :responding_block, :options
    def initialize(matcher, options, responding_block)
      @matcher = matcher
      @options = options
      @responding_block = responding_block
    end

    def matches(receiver, method)
      matcher.matches(receiver, method)
    end
    alias_method :matches?, :matches

    def call(instance, klass, method, passed_args, passed_block)
      match_result = [matches(instance, method)].flatten(1)

      if create_method?
        klass.class_exec(responding_block) do |respond_with|
          define_method(method) do |*args, &block|
            instance_exec(*(match_result + args).flatten(1), &respond_with)
          end
        end

        instance.send(method, *passed_args, &passed_block)
      else
        instance.instance_exec(*(match_result + passed_args).flatten(1), &responding_block)
      end
    end

    def self.from(matcher, options, block)
      raise ArgumentError, "Must specify a block to create a ghost_method" unless block

      if matcher.nil?
        unless options.empty?
          raise ArgumentError, "You cannot specify creation options if you're \
              using the shorthand...specify those options in the DSL instead"
        end

        using_dsl(&block)
      else
        using_dsl do
          options.each {|k, v| send(k, v) }
          match_with(matcher)
          respond_with(&block)
        end
      end
    end

    private

    def create_method?
      options[:create_method]
    end

    def self.using_dsl(&block)
      Responder::DSL.new.tap do |dsl|
        dsl.instance_eval(&block)
      end.to_responder
    end
  end
end
