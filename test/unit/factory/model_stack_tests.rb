require 'assert'
require 'mr/factory/model_stack'

class MR::Factory::ModelStack

  class UnitTests < Assert::Context
    desc "MR::Factory::ModelStack"
    setup do
      @model = TestModel.new
      @record_stack_spy = RecordStackSpy.new
      MR::Factory::RecordStack.stubs(:new).tap do |s|
        s.with(@model.record)
        s.returns(@record_stack_spy)
      end
      @stack = MR::Factory::ModelStack.new(@model)
    end
    teardown do
      MR::Factory::RecordStack.unstub(:new)
    end
    subject{ @stack }

    should have_readers :model
    should have_imeths :create, :destroy
    should have_imeths :create_dependencies, :destroy_dependencies

    should "call the record stack `create` using `create`" do
      subject.create
      assert_true @record_stack_spy.create_called
    end

    should "call the record stack `destroy` using `destroy`" do
      subject.destroy
      assert_true @record_stack_spy.destroy_called
    end

    should "call the record stack `create_dependencies` using `create_dependencies`" do
      subject.create_dependencies
      assert_true @record_stack_spy.create_dependencies_called
    end

    should "call the record stack `destroy_dependencies` using `destroy_dependencies`" do
      subject.destroy_dependencies
      assert_true @record_stack_spy.destroy_dependencies_called
    end

  end

  class RecordStackSpy
    attr_reader :create_called, :destroy_called
    attr_reader :create_dependencies_called, :destroy_dependencies_called

    def initialize
      @create_called  = false
      @destroy_called = false
      @create_dependencies_called  = false
      @destroy_dependencies_called = false
    end

    def create
      @create_called = true
    end

    def destroy
      @destroy_called = true
    end

    def create_dependencies
      @create_dependencies_called = true
    end

    def destroy_dependencies
      @destroy_dependencies_called = true
    end
  end

  class TestRecord
    include MR::Record

  end

  class TestModel
    include MR::Model
    record_class TestRecord

    public :record

  end

end
