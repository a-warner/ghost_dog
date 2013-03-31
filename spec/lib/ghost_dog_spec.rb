require 'spec_helper'

describe GhostDog do
  subject { described_class }
  it { should_not be_nil }

  context 'simple responder' do
    class Minimal
      include GhostDog

      ghost_method /^tell_me_(.+)$/ do |what_to_tell|
        what_to_tell.gsub('_', ' ')
      end
    end

    let(:obj) { Minimal.new }
    subject { obj }
    its(:tell_me_hello_world) { should == "hello world" }
    it { should respond_to(:tell_me_hello_world) }

    context 'defines method' do
      let(:obj) { Minimal.new }
      before { obj.tell_me_whatup }

      its(:public_methods) { should include :tell_me_whatup }
      its(:tell_me_whatup) { should == "whatup" }
    end
  end

  context 'class level responder' do
    class ClassLevel
      class << self
        include GhostDog

        ghost_method /^say_([^_]+)_to_(.+)$/ do |what, name|
          "#{what}, #{name}!"
        end
      end
    end

    let(:obj) { ClassLevel }
    subject { obj }

    its(:say_hello_to_andrew) { should == "hello, andrew!" }
    it { should respond_to(:say_goodbye_to_max) }
    it { should_not respond_to(:tell_max_hello) }
    its(:public_methods) { should include :say_hello_to_andrew }

    context 'another class' do
      class AnotherClass; end
      let(:obj) { AnotherClass }
      it { should_not respond_to(:say_hello_to_andrew) }
    end
  end

  context 'inheritable method_missing' do
    class SuperKlass
      class << self
        include GhostDog

        ghost_method /^call_an_([^_]+)_overridable_method$/ do |text|
          "#{text} #{overridable_method}"
        end

        def overridable_method
          "SuperKlass"
        end
      end

      include GhostDog

      ghost_method /^instance_methods_say_(.+)$/ do |what_to_say|
        "#{greeting} #{what_to_say}"
      end

      def greeting
        "Super greeting"
      end
    end

    class SubKlass < SuperKlass
      def self.overridable_method
        "SubKlass"
      end

      def greeting
        "Sub greeting"
      end
    end

    subject { obj }

    context SuperKlass do
      let(:obj) { SuperKlass }
      its(:call_an_awesome_overridable_method) { should == 'awesome SuperKlass' }

      context 'instance' do
        let(:obj) { SuperKlass.new }
        its(:instance_methods_say_salutations) { should == "Super greeting salutations" }
      end
    end

    context SubKlass do
      let(:obj) { SubKlass }
      its(:call_an_awesome_overridable_method) { should == 'awesome SubKlass' }

      context 'instance' do
        let(:obj) { SubKlass.new }
        its(:instance_methods_say_salutations) { should == "Sub greeting salutations" }
      end
    end
  end

  context 'complex matchers' do
    class ComplexExample
      include GhostDog

      def names
        ['ishmael', 'dave']
      end

      ghost_method do
        match_with do |method_name|
          if match = method_name.match(/^call_me_(#{names.join('|')})$/)
            match.to_a.drop(1)
          end
        end

        respond_with do |name|
          "what's going on #{name}?"
        end
      end
    end

    subject { obj }

    let(:obj) { ComplexExample.new }

    it { should_not respond_to(:call_me_john) }
    ['ishmael', 'dave'].each do |name|
      it { should respond_to(:"call_me_#{name}") }
      its(:"call_me_#{name}") { should == "what's going on #{name}?" }
    end

    context 'custom matcher class' do
      class CustomMatcher
        def matches(receiver, method_name)
          method_name == 'andrew' && method_name
        end
      end

      class CustomMatcher2
        def matches(receiver, method_name)
          method_name == 'john' && method_name
        end
      end

      class CustomMatcherExample
        include GhostDog

        ghost_method do
          match_with CustomMatcher.new

          respond_with do |name|
            "that's a cool matcher #{name}"
          end
        end

        ghost_method CustomMatcher2.new do |name|
          "more concise, #{name}!"
        end
      end

      let(:obj) { CustomMatcherExample.new }

      it { should respond_to(:andrew) }
      its(:andrew) { should == "that's a cool matcher andrew" }
      it { should respond_to(:john) }
      its(:john) { should == "more concise, john!" }

    end

    context 'superclass and subclass' do
      def self.setup_superclass(super_class)

        super_class.class_eval do
          include GhostDog

          ghost_method do
            match_with do |method_name|
              if match = method_name.match(/^(#{names.join('|')})$/)
                match.to_a.drop(1)
              end
            end

            respond_with do |name|
              "hello mr #{name}"
            end
          end
        end

      end

      def self.setup_subclasses(sub_class_1, sub_class_2)
        sub_class_1.class_eval do
          def names; ['james', 'john']; end
        end

        sub_class_2.class_eval do
          def names; ['anna', 'margaret']; end
        end
      end

      def self.name_examples_for(names)
        names.each do |name|
          it { should respond_to(name) }
          its(name) { should == "hello mr #{name}" }
        end
      end

      def self.non_responding_examples_for(names)
        names.map(&:to_sym).each do |name|
          it { should_not respond_to(name) }
          it 'should raise NoMethodError' do
            expect { send(name) }.to raise_exception NoMethodError
          end
        end
      end

      def self.name_examples(ctx, obj, options)
        context ctx do
          let(:obj) { obj }
          name_examples_for(options.fetch(:responds_to))
          non_responding_examples_for(options.fetch(:non_responses))
        end
      end

      class SuperClass; end
      setup_superclass(SuperClass)
      class SubClassA < SuperClass; end
      class SubClassB < SuperClass; end
      setup_subclasses(SubClassA, SubClassB)

      subject { obj }

      name_examples(SubClassA, SubClassA.new,
                    :responds_to => ['james', 'john'],
                    :non_responses => ['anna', 'margaret'])
      name_examples(SubClassB, SubClassB.new,
                    :responds_to => ['anna', 'margaret'],
                    :non_responses => ['james', 'john'])

      class SuperEigenClass; end
      setup_superclass(SuperEigenClass.singleton_class)
      class SubEigenclassA < SuperEigenClass; end
      class SubEigenclassB < SuperEigenClass; end
      setup_subclasses(SubEigenclassA.singleton_class, SubEigenclassB.singleton_class)

      name_examples(SubEigenclassA.singleton_class, SubEigenclassA,
                    :responds_to => ['james', 'john'],
                    :non_responses => ['anna', 'margaret'])
      name_examples(SubEigenclassB.singleton_class, SubEigenclassB,
                    :responds_to => ['anna', 'margaret'],
                    :non_responses => ['james', 'john'])
    end
  end

  context 'missing method' do
    class Broken
      include GhostDog

      ghost_method /\Ahello_(.+)\Z/ do |name|
        method_that_doesnt_exist(name)
      end

      ghost_method do
        match_with do |method_name|
          nothing_to_see_here(method_name)
        end

        respond_with do |something|
          raise "I shouldn't be called..."
        end
      end
    end

    subject { Broken.new }

    context 'in method definition' do
      it 'should raise error' do
        expect { subject.hello_world }.to raise_error NoMethodError
      end
    end

    context 'in method matcher' do
      it 'should raise error' do
        expect { subject.foo_bar }.to raise_error NoMethodError
      end
    end
  end

  context 'calling ghost method from a ghost method' do
    class DoubleGhost
      include GhostDog

      ghost_method /\Ahello_(.+)\Z/ do |name|
        "hello to you, #{name}"
      end

      ghost_method /\Afoo_(.+)\Z/ do |after_foo|
        send(:"hello_#{after_foo}")
      end
    end

    subject { DoubleGhost.new }

    its(:foo_bar) { should == "hello to you, bar" }
  end
end
