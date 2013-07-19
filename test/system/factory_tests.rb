require 'assert'
require 'mr/factory'

require 'test/support/setup_test_db'
require 'test/support/models/user'
require 'test/support/models/user_record'

module MR::Factory

  class SystemTests < Assert::Context
    desc "MR::Factory for records and models"
    subject{ MR::Factory }

    should "return a MR::Factory::Record class with #new given an MR::Record" do
      factory = subject.new(UserRecord)
      assert_instance_of MR::Factory::RecordFactory, factory
    end

    should "return a MR::Factory::Model class with #new given an MR::Model" do
      factory = subject.new(User)
      assert_instance_of MR::Factory::ModelFactory, factory
    end

    should "pass args and blocks through to the individual factories" do
      factory = subject.new(User, FakeUserRecord) do
        default_args :test => true
      end
      assert_equal FakeUserRecord,    factory.instance_variable_get("@fake_record_class")
      assert_equal({ :test => true }, factory.default_args)
    end

  end

end
