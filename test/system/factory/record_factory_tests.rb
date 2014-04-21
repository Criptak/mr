require 'assert'
require 'mr/factory/record_factory'

require 'test/support/setup_test_db'
require 'test/support/models/area'
require 'test/support/models/user'

class MR::Factory::RecordFactory

  class SystemTests < DbTests
    desc "MR::Factory::Model"
    setup do
      @factory_class = MR::Factory::RecordFactory
    end

  end

  class BuildingRealRecordTests < SystemTests
    setup do
      @factory = @factory_class.new(UserRecord)
    end
    subject{ @factory }

    should "build a record with it's attributes set using `instance`" do
      user_record = subject.instance
      assert_instance_of UserRecord, user_record
      assert_true user_record.new_record?
      assert_kind_of String,  user_record.name
      assert_kind_of Integer, user_record.number
      assert_kind_of Date,    user_record.started_on
      assert_kind_of Time,    user_record.dob
      assert_true user_record.salary.kind_of?(Float) || user_record.salary.kind_of?(BigDecimal)
      assert_nil user_record.area_id
    end

    should "build a record and save it using `saved_instance`" do
      area_factory = @factory_class.new(AreaRecord)
      area_record = area_factory.instance.tap(&:save)

      user_record = subject.saved_instance(:area => area_record)
      assert_instance_of UserRecord, user_record
      assert_false user_record.new_record?
    end

    should "build a record stack for an instance using `instance_stack`" do
      stack = subject.instance_stack
      assert_instance_of MR::Factory::RecordStack, stack
    end

  end

end
