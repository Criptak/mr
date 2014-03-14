require 'assert'
require 'mr/factory/model_factory'

require 'mr/fake_record'
require 'mr/model'
require 'mr/record'

class MR::Factory::ModelFactory

  class UnitTests < Assert::Context
    desc "MR::Factory::ModelFactory"
    setup do
      @factory_class = MR::Factory::ModelFactory
    end
    subject{ @factory_class }

    should "include the apply args mixin" do
      assert_includes MR::Factory::ApplyArgs, subject
    end

  end

  class InstanceTests < UnitTests
    setup do
      @model_class       = TestModel
      @record_class      = @model_class.record_class
      @fake_record_class = TestFakeRecord

      @record_factory      = MR::Factory::RecordFactory.new(@record_class)
      @fake_record_factory = MR::Factory::RecordFactory.new(@fake_record_class)

      MR::Factory::RecordFactory.stubs(:new).tap do |s|
        s.with(@record_class)
        s.returns(@record_factory)
      end
      MR::Factory::RecordFactory.stubs(:new).tap do |s|
        s.with(@fake_record_class)
        s.returns(@fake_record_factory)
      end

      @factory = @factory_class.new(@model_class, @fake_record_class)
    end
    teardown do
      MR::Factory::RecordFactory.unstub(:new)
    end
    subject{ @factory }

    should have_imeths :instance, :instance_stack
    should have_imeths :fake, :fake_stack
    should have_imeths :apply_args
    should have_imeths :default_args, :default_instance_args, :default_fake_args

    should "allow applying args to a model using `apply_args`" do
      @model = @model_class.new
      subject.apply_args(@model, :name => 'test')
      assert_equal 'test', @model.name
    end

    should "use default args when applying args using `apply_args`" do
      @model = @model_class.new
      subject.default_args(:name => 'test')
      subject.apply_args(@model)
      assert_equal 'test', @model.name
    end

    should "use passed args over default args using `apply_args`" do
      @model = @model_class.new
      subject.default_args(:name => 'first')
      subject.apply_args(@model, :name => 'second')
      assert_equal 'second', @model.name
    end

    should "allow reading/writing default args using `default_args`" do
      assert_equal({}, subject.default_args)
      subject.default_args(:name => 'test')
      assert_equal({ 'name' => 'test' }, subject.default_args)
    end

    should "allow reading/writing default args using `default_instance_args`" do
      assert_equal({}, subject.default_instance_args)
      subject.default_instance_args(:name => 'test')
      assert_equal({ 'name' => 'test' }, subject.default_instance_args)
    end

    should "allow reading/writing default args using `default_fake_args`" do
      assert_equal({}, subject.default_fake_args)
      subject.default_fake_args(:name => 'test')
      assert_equal({ 'name' => 'test' }, subject.default_fake_args)
    end

    should "yield itself when a block is passed to `new`" do
      yielded = nil
      factory = @factory_class.new(@model_class){ yielded = self }
      assert_equal factory, yielded
    end

  end

  class InstanceMethodTests < InstanceTests
    desc "instance"
    setup do
      @record = @record_class.new
      @record_factory.stubs(:instance).returns(@record)
    end

    should "return an instance of the model" do
      model = subject.instance
      assert_instance_of @model_class, model
    end

    should "build a record instance for the model using a record factory" do
      model = subject.instance
      assert_same @record, model.record
    end

    should "apply passed args to the model" do
      model = subject.instance(:name => 'test')
      assert_equal 'test', model.name
    end

    should "apply default instance args to the model" do
      subject.default_instance_args(:name => 'test')
      model = subject.instance
      assert_equal 'test', model.name
    end

    should "apply default args to the model" do
      subject.default_args(:name => 'test')
      model = subject.instance
      assert_equal 'test', model.name
    end

    should "apply passed args over default instance args to the model" do
      subject.default_instance_args(:name => 'first')
      model = subject.instance(:name => 'second')
      assert_equal 'second', model.name
    end

    should "apply default instance args over default args to the model" do
      subject.default_args(:name => 'first')
      subject.default_instance_args(:name => 'second')
      model = subject.instance
      assert_equal 'second', model.name
    end

  end

  class InstanceStackTests < InstanceTests
    desc "instance_stack"
    setup do
      @model = @model_class.new
      @factory.stubs(:instance).with(nil).returns(@model)

      @model_stack = 'a-model-stack'
      MR::Factory::ModelStack.stubs(:new).tap do |s|
        s.with(@model)
        s.returns(@model_stack)
      end

      @model_with_args = @model_class.new
      @factory.stubs(:instance).with(:name => 'test').returns(@model_with_args)

      @args_model_stack = 'a-model-stack-with-args'
      MR::Factory::ModelStack.stubs(:new).tap do |s|
        s.with(@model_with_args)
        s.returns(@args_model_stack)
      end
    end
    teardown do
      MR::Factory::ModelStack.unstub(:new)
    end

    should "return a model stack for an instance generated by itself" do
      assert_equal @model_stack, subject.instance_stack
    end

    should "pass args when generating an instance for the model stack" do
      assert_equal @args_model_stack, subject.instance_stack(:name => 'test')
    end

  end

  class FakeTests < InstanceTests
    desc "fake"
    setup do
      @fake_record = @fake_record_class.new
      @fake_record_factory.stubs(:instance).returns(@fake_record)
    end

    should "return an instance of the model" do
      model = subject.fake
      assert_instance_of @model_class, model
    end

    should "build a fake record instance for the model using a record factory" do
      model = subject.fake
      assert_same @fake_record, model.record
    end

    should "apply passed args to the model" do
      model = subject.fake(:name => 'test')
      assert_equal 'test', model.name
    end

    should "apply default fake args to the model" do
      subject.default_fake_args(:name => 'test')
      model = subject.fake
      assert_equal 'test', model.name
    end

    should "apply default args to the model" do
      subject.default_args(:name => 'test')
      model = subject.fake
      assert_equal 'test', model.name
    end

    should "apply passed args over default fake args to the model" do
      subject.default_fake_args(:name => 'first')
      model = subject.fake(:name => 'second')
      assert_equal 'second', model.name
    end

    should "apply default fake args over default args to the model" do
      subject.default_args(:name => 'first')
      subject.default_fake_args(:name => 'second')
      model = subject.fake
      assert_equal 'second', model.name
    end

    should "raise an exception if the factory isn't created with " \
           "a fake record class" do
      factory = @factory_class.new(@model_class)
      assert_raises(RuntimeError){ factory.fake }
    end

  end

  class FakeStackTests < InstanceTests
    desc "fake_stack"
    setup do
      @model = @model_class.new
      @factory.stubs(:fake).with(nil).returns(@model)

      @model_stack = 'a-model-stack'
      MR::Factory::ModelStack.stubs(:new).tap do |s|
        s.with(@model)
        s.returns(@model_stack)
      end

      @model_with_args = @model_class.new
      @factory.stubs(:fake).with(:name => 'test').returns(@model_with_args)

      @args_model_stack = 'a-model-stack-with-args'
      MR::Factory::ModelStack.stubs(:new).tap do |s|
        s.with(@model_with_args)
        s.returns(@args_model_stack)
      end
    end
    teardown do
      MR::Factory::ModelStack.unstub(:new)
    end

    should "return a model stack for a fake generated by itself" do
      assert_equal @model_stack, subject.fake_stack
    end

    should "pass args when generating a fake for the model stack" do
      assert_equal @args_model_stack, subject.fake_stack(:name => 'test')
    end

  end

  class DupArgsTests < InstanceTests
    desc "building multiple models"
    setup do
      @model_class.record_class(@fake_record_class)
      @factory = @factory_class.new(@model_class, @fake_record_class)
      @factory.default_args(:user => { :area => { :name => 'Test' } })
    end
    teardown do
      @model_class.record_class(@record_class)
    end

    should "not alter the defaults hash when applying args" do
      assert_equal 'Test', @factory.instance.user.area.name
      assert_equal 'Test', @factory.instance.user.area.name
      assert_equal 'Test', @factory.fake.user.area.name
      assert_equal 'Test', @factory.fake.user.area.name
    end

  end

  class TestRecord
    include MR::Record

    attr_accessor :name

  end

  class TestModel
    include MR::Model
    record_class TestRecord

    field_accessor :name

    belongs_to :area
    belongs_to :user

    public :record

  end

  class TestFakeRecord
    include MR::FakeRecord
    model_class TestModel

    attribute :name,    :string
    attribute :area_id, :integer
    attribute :user_id, :integer

    belongs_to :area, 'MR::Factory::ModelFactory::TestFakeRecord'
    belongs_to :user, 'MR::Factory::ModelFactory::TestFakeRecord'

  end

end
