require 'assert'
require 'mr/record_factory'

require 'test/support/setup_test_db'
require 'test/support/models/user'

class MR::RecordFactory

  class SystemTests < DbTests
    desc "MR::RecordFactory"
    setup do
      @factory_class = MR::RecordFactory
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
      assert user_record.new_record?
      assert_kind_of String,  user_record.name
      assert_kind_of Integer, user_record.number
      assert_kind_of Date,    user_record.started_on
      assert_kind_of Time,    user_record.dob
      assert_true user_record.salary.kind_of?(Float) || user_record.salary.kind_of?(BigDecimal)
      assert_nil user_record.area_id
    end

    should "build a record stack for an instance using `instance_stack`" do
      stack = subject.instance_stack
      assert_instance_of MR::RecordStack, stack
    end

  end

end
