require 'assert'
require 'mr/factory/model_factory'

require 'test/support/setup_test_db'
require 'test/support/models/user'

class MR::Factory::ModelFactory

  class SystemTests < DbTests
    desc "MR::Factory::Model"
    setup do
      @factory_class = MR::Factory::ModelFactory
    end

  end

  class BuildingRealModelTests < SystemTests
    setup do
      @factory = @factory_class.new(User, UserRecord)
    end
    subject{ @factory }

    should "build a model with it's fields set using `instance`" do
      user = subject.instance
      assert_instance_of User, user
      assert_instance_of UserRecord, user.send(:record)
      assert user.new?
      assert_kind_of String,  user.name
      assert_kind_of Integer, user.number
      assert_kind_of Date,    user.started_on
      assert_kind_of Time,    user.dob
      assert_true user.salary.kind_of?(Float) || user.salary.kind_of?(BigDecimal)
      assert_nil user.area_id
    end

    should "build a model stack for an instance using `instance_stack`" do
      stack = subject.instance_stack
      assert_instance_of MR::Factory::ModelStack, stack
    end

  end

  class BuildingFakeModelTests < SystemTests
    setup do
      @factory = @factory_class.new(User, FakeUserRecord)
    end
    subject{ @factory }

    should "build a model with it's fields set using `instance`" do
      user = subject.instance
      assert_instance_of User, user
      assert_instance_of FakeUserRecord, user.send(:record)
      assert user.new?
      assert_kind_of String,     user.name
      assert_kind_of Integer,    user.number
      assert_kind_of Date,       user.started_on
      assert_kind_of Time,       user.dob
      assert_true user.salary.kind_of?(Float) || user.salary.kind_of?(BigDecimal)
      assert_nil user.area_id
    end

    should "build a model stack for an instance using `instance_stack`" do
      stack = subject.instance_stack
      assert_instance_of MR::Factory::ModelStack, stack
    end

  end

end
