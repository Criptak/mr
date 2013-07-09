require 'assert'
require 'mr/factory/record_factory'

require 'test/support/setup_test_db'
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

    should have_imeths :instance, :instance_stack, :default_attributes

    should "return values for non-association attributes on a UserRecord " \
           "with #default_attributes" do
      attrs = subject.default_attributes
      assert_instance_of String, attrs['name']
      assert_instance_of String, attrs['email']
      assert_instance_of DateTime, attrs['created_at']
      assert_instance_of DateTime, attrs['updated_at']
      assert_equal MR::Factory.boolean, attrs['active']
    end

    should "return a UserRecord with it's columns defaulted with #instance" do
      user_record = subject.instance
      assert user_record.new_record?
      assert_instance_of String, user_record.name
      assert_instance_of String, user_record.email
      assert_instance_of DateTime, user_record.created_at
      assert_instance_of DateTime, user_record.updated_at
      assert_equal MR::Factory.boolean, user_record.active
      assert_nil user_record.area_id

      user_record = subject.instance(:name => nil, :active => false)
      assert_equal nil,   user_record.name
      assert_equal false, user_record.active
    end

    should "allow providing defaults when building a new factory" do
      factory = MR::Factory::RecordFactory.new(UserRecord, {
        :name   => nil,
        :active => false
      })
      user_record = factory.instance(:name => 'Test')
      assert_equal 'Test', user_record.name
      assert_equal false,  user_record.active
      assert_not_nil user_record.email
    end

    should "return a UserRecord stack with #instance_stack" do
      factory = MR::Factory::RecordFactory.new(UserRecord, {
        :name   => nil,
        :active => false
      })
      stack = factory.instance_stack(:name => 'Test')
      assert_instance_of MR::Stack::RecordStack, stack
      user_record = stack.record
      assert_instance_of UserRecord, user_record
      assert_equal 'Test', user_record.name
      assert_equal false,  user_record.active
      assert_not_nil user_record.email
    end

    should "work with a fake record" do
      factory = MR::Factory::RecordFactory.new(FakeUserRecord)
      fake_user_record = factory.instance
      assert fake_user_record.new_record?
      assert_instance_of String, fake_user_record.name
      assert_instance_of String, fake_user_record.email
      assert_instance_of DateTime, fake_user_record.created_at
      assert_instance_of DateTime, fake_user_record.updated_at
      assert_equal MR::Factory.boolean, fake_user_record.active
      assert_nil fake_user_record.area_id

      fake_stack = factory.instance_stack
      assert_instance_of MR::Stack::RecordStack, fake_stack
      fake_user_record = fake_stack.record
      assert_instance_of FakeUserRecord, fake_user_record
    end

  end

end
