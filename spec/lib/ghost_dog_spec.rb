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
        matcher do |method_name|
          if match = method_name.match(/^call_me_(#{names.join('|')})$/)
            match.to_a.drop(1)
          end
        end

        responder do |name|
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

    context 'superclass and subclass' do
      class SuperClass
        include GhostDog

        ghost_method do
          matcher do |method_name|
            if match = method_name.match(/^(#{names.join('|')})$/)
              match.to_a.drop(1)
            end
          end

          responder do |name|
            "hello mr #{name}"
          end
        end
      end

      class A < SuperClass
        def names; ['james', 'john']; end
      end

      class B < SuperClass
        def names; ['anna', 'margaret']; end
      end

      subject { obj }

      def self.name_examples_for(*names)
        names.each do |name|
          it { should respond_to(name) }
          its(name) { should == "hello mr #{name}" }
        end
      end

      def self.non_responding_examples_for(*names)
        names.map(&:to_sym).each do |name|
          it { should_not respond_to(name) }
          it 'should raise NoMethodError' do
            expect { send(name) }.to raise_exception NoMethodError
          end
        end
      end

      context A do
        let(:obj) { A.new }
        name_examples_for('james', 'john')
        non_responding_examples_for('anna', 'margaret')
      end

      context B do
        let(:obj) { B.new }
        name_examples_for('anna', 'margaret')
        non_responding_examples_for('james', 'john')
      end
    end
  end
end
