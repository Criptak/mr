require 'assert'
require 'mr/factory/record_factory'

require 'test/support/setup_test_db'
require 'test/support/models/comment_record'
require 'test/support/models/fake_user_record'
require 'test/support/models/user'
require 'test/support/models/user_record'

class MR::Factory::RecordFactory

  class BaseTests < Assert::Context
    desc "MR::Factory::RecordFactory"
    setup do
      @factory = MR::Factory::RecordFactory.new(UserRecord)
    end
    subject{ @factory }

    should have_imeths :instance, :instance_stack, :apply_args, :default_args

    should "allow reading and writing default args with #default_args" do
      subject.default_args(:test => true)
      assert_equal({ :test => true }, subject.default_args)
    end

    should "allow passing a block when it's initialized" do
      factory = MR::Factory::ModelFactory.new(User) do
        default_args :test => true
      end
      assert_equal({ :test => true }, factory.default_args)
    end

    should "allow applying hash args to a record with #apply_args" do
      user_record = UserRecord.new
      subject.apply_args(user_record, :name => 'Test')
      assert_equal 'Test', user_record.name
    end

    should "allow applying proc values to a record with #apply_args" do
      area_factory = MR::Factory::RecordFactory.new(AreaRecord)
      args = { :area => proc{ area_factory.instance } }
      user_record = UserRecord.new
      subject.apply_args(user_record, args)
      assert_instance_of AreaRecord, user_record.area
      other_user_record = UserRecord.new
      subject.apply_args(other_user_record, args)
      assert_instance_of AreaRecord, other_user_record.area
      assert_not_same user_record.area, other_user_record.area
    end

    should "allow applying hash args to an associated record with #apply_args" do
      user_record = UserRecord.new.tap{ |u| u.area = AreaRecord.new }
      subject.apply_args(user_record, :area => { :name => 'Test' })
      assert_equal 'Test', user_record.area.name
    end

    should "build and apply args to an associated record with #apply_args" do
      user_record = UserRecord.new
      subject.apply_args(user_record, :area => { :name => 'Test' })
      assert_equal 'Test', user_record.area.name
    end

    should "build an instance of the record with it's attributes set, " \
           "using #instance" do
      user_record = subject.instance
      assert_instance_of UserRecord, user_record
      assert user_record.new_record?
      assert_instance_of String,   user_record.name
      assert_instance_of String,   user_record.email
      assert_instance_of DateTime, user_record.created_at
      assert_instance_of DateTime, user_record.updated_at
      assert_equal MR::Factory.boolean, user_record.active
    end

    should "build an instance stack for the record with it's attributes set, " \
           "using #instance_stack" do
      stack = subject.instance_stack
      assert_instance_of MR::Factory::RecordStack, stack
      user_record = stack.record
      assert_instance_of UserRecord, user_record
      assert user_record.new_record?
      assert_instance_of String,   user_record.name
      assert_instance_of String,   user_record.email
      assert_instance_of DateTime, user_record.created_at
      assert_instance_of DateTime, user_record.updated_at
      assert_equal MR::Factory.boolean, user_record.active
    end

  end

  class FakeRecordTests < BaseTests
    desc "with a fake record"
    setup do
      @factory = MR::Factory::RecordFactory.new(FakeUserRecord)
    end

    should "allow passing a block when it's initialized" do
      factory = MR::Factory::ModelFactory.new(User) do
        default_args :test => true
      end
      assert_equal({ :test => true }, factory.default_args)
    end

    should "allow applying hash args to a record with #apply_args" do
      user_record = FakeUserRecord.new
      subject.apply_args(user_record, :name => 'Test')
      assert_equal 'Test', user_record.name
    end

    should "allow applying proc values to a record with #apply_args" do
      area_factory = MR::Factory::RecordFactory.new(FakeAreaRecord)
      args = { :area => proc{ area_factory.instance } }
      user_record = FakeUserRecord.new
      subject.apply_args(user_record, args)
      assert_instance_of FakeAreaRecord, user_record.area
      other_user_record = FakeUserRecord.new
      subject.apply_args(other_user_record, args)
      assert_instance_of FakeAreaRecord, other_user_record.area
      assert_not_same user_record.area, other_user_record.area
    end

    should "allow applying hash args to an associated record with #apply_args" do
      user_record = FakeUserRecord.new.tap{ |u| u.area = FakeAreaRecord.new }
      subject.apply_args(user_record, :area => { :name => 'Test' })
      assert_equal 'Test', user_record.area.name
    end

    should "build and apply args to an associated record with #apply_args" do
      user_record = FakeUserRecord.new
      subject.apply_args(user_record, :area => { :name => 'Test' })
      assert_equal 'Test', user_record.area.name
    end

    should "build an instance of the record with it's attributes set, " \
           "using #instance" do
      user_record = subject.instance
      assert_instance_of FakeUserRecord, user_record
      assert user_record.new_record?
      assert_instance_of String,   user_record.name
      assert_instance_of String,   user_record.email
      assert_instance_of DateTime, user_record.created_at
      assert_instance_of DateTime, user_record.updated_at
      assert_equal MR::Factory.boolean, user_record.active
    end

    should "build an instance stack for the record with it's attributes set, " \
           "using #instance_stack" do
      stack = subject.instance_stack
      assert_instance_of MR::Factory::RecordStack, stack
      user_record = stack.record
      assert_instance_of FakeUserRecord, user_record
      assert user_record.new_record?
      assert_instance_of String,   user_record.name
      assert_instance_of String,   user_record.email
      assert_instance_of DateTime, user_record.created_at
      assert_instance_of DateTime, user_record.updated_at
      assert_equal MR::Factory.boolean, user_record.active
    end

  end

  class WithDefaultArgsTests < BaseTests
    desc "with default args"
    setup do
      @factory = MR::Factory::RecordFactory.new(UserRecord) do
        default_args({
          :name   => 'Test',
          :email  => 'test@example.com',
          :active => true
        })
      end
    end

    should "use the default args with #apply_args" do
      user_record = UserRecord.new
      subject.apply_args(user_record)
      assert_equal 'Test',             user_record.name
      assert_equal 'test@example.com', user_record.email
      assert_equal true,               user_record.active
    end

    should "use the default args with #instance" do
      user_record = subject.instance
      assert_equal 'Test',             user_record.name
      assert_equal 'test@example.com', user_record.email
      assert_equal true,               user_record.active
    end

    should "use the default args with #instance_stack" do
      stack = subject.instance_stack
      user_record = stack.record
      assert_equal 'Test',             user_record.name
      assert_equal 'test@example.com', user_record.email
      assert_equal true,               user_record.active
    end

    should "allow overwriting the defaults by passing args to #apply_args" do
      user_record = UserRecord.new
      subject.apply_args(user_record, :name => 'Not Test')
      assert_equal 'Not Test',         user_record.name
      assert_equal 'test@example.com', user_record.email
      assert_equal true,               user_record.active
    end

    should "allow overwriting the defaults by passing args to #instance" do
      user_record = subject.instance(:name => 'Not Test')
      assert_equal 'Not Test',         user_record.name
      assert_equal 'test@example.com', user_record.email
      assert_equal true,               user_record.active
    end

    should "allow overwriting the defaults by passing args to #instance_stack" do
      stack = subject.instance_stack(:name => 'Not Test')
      user_record = stack.record
      assert_equal 'Not Test',         user_record.name
      assert_equal 'test@example.com', user_record.email
      assert_equal true,               user_record.active
    end

  end

  class DeepMergeTests < BaseTests
    desc "with deeply nested args"
    setup do
      @factory = MR::Factory::RecordFactory.new(CommentRecord) do
        default_args :user => { :name => 'Test' }
      end
    end

    should "deeply merge the args preserving both the defaults and " \
           "what was passed when applying args" do
      comment_record = @factory.instance({
        :user => { :email => 'test@example.com' }
      })
      user_record = comment_record.user
      assert_equal 'Test',             user_record.name
      assert_equal 'test@example.com', user_record.email
    end

  end

  class DupArgsTests < BaseTests
    desc "using a factory multiple times"
    setup do
      @factory = MR::Factory::RecordFactory.new(CommentRecord) do
        default_args :user => { :area => { :name => 'Test' } }
      end
    end

    should "not alter the defaults hash when applying args" do
      assert_equal 'Test', @factory.instance.user.area.name
      assert_equal 'Test', @factory.instance.user.area.name
    end

  end

end
