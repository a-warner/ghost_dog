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
end
