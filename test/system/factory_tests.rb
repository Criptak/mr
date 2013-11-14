require 'assert'
require 'mr/factory'

require 'test/support/setup_test_db'
require 'test/support/models/user'

module MR::Factory

  class SystemTests < Assert::Context
    desc "MR::Factory for records and models"
    subject{ MR::Factory }

    should "return a RecordFactory when a Record is passed to `new`" do
      factory = subject.new(UserRecord)
      assert_instance_of MR::Factory::RecordFactory, factory
    end

    should "return a ModelFactory when a Model is passed to `new`" do
      factory = subject.new(User)
      assert_instance_of MR::Factory::ModelFactory, factory
    end

    should "return a ReadModelFactory when a ReadModel is passed to `new`" do
      read_model_class = Class.new{ include MR::ReadModel }
      factory = subject.new(read_model_class)
      assert_instance_of MR::Factory::ReadModelFactory, factory
    end

    should "pass args and blocks through to the individual factories" do
      factory = subject.new(User, FakeUserRecord) do
        default_args :test => true
      end
      assert_equal FakeUserRecord,    factory.instance_variable_get("@fake_record_class")
      assert_equal({ 'test' => true }, factory.default_args)
    end

  end

end
