require 'assert'
require 'mr/factory'

require 'test/support/ar_models'
require 'test/support/db_schema_context'

module MR::Factory

  class SystemTests < DBSchemaTests
    desc "MR::Factory for records and models"
    subject{ MR::Factory }

    should "return a MR::Factory::Record class with #new given an MR::Record" do
      factory = subject.new(UserRecord)
      assert_instance_of MR::Factory::Record, factory
    end

    should "return a MR::Factory::Model class with #new given an MR::Model" do
      factory = subject.new(User)
      assert_instance_of MR::Factory::Model, factory
    end

  end

  class RecordTests < SystemTests
    desc "MR::Factory::Record"
    setup do
      @factory = MR::Factory::Record.new(UserRecord)
    end
    subject{ @factory }

    should have_imeths :instance, :default_attributes

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

      user_record = subject.instance(:name => nil, :active => false)
      assert_equal nil,   user_record.name
      assert_equal false, user_record.active
    end

    should "allow providing defaults when building a new factory" do
      factory = MR::Factory::Record.new(UserRecord, :name => nil, :active => false)
      user_record = factory.instance(:name => 'Test')
      assert_equal 'Test', user_record.name
      assert_equal false,  user_record.active
      assert_not_nil user_record.email
    end

  end

  class ModelTests < SystemTests
    desc "MR::Factory::Model"
    setup do
      @factory = MR::Factory::Model.new(User)
    end
    subject{ @factory }

    should have_imeths :instance, :fake

    should "build an instance of the model with the fake record class and "\
          "allow setting fields with #fake" do
      assert_raises(RuntimeError){ subject.fake }

      factory = MR::Factory::Model.new(User, FakeUserRecord)
      fake_user = factory.fake
      assert_instance_of User,           fake_user
      assert_instance_of FakeUserRecord, fake_user.send(:record)

      fake_user = factory.fake(:name => 'Test')
      assert_equal 'Test', fake_user.name
    end

    should "build an instance of the model and allow setting fields " \
           "with #instance" do
      user = subject.instance
      assert_instance_of User,       user
      assert_instance_of UserRecord, user.send(:record)
      assert user.new?
      assert_instance_of String, user.name
      assert_instance_of String, user.email
      assert_instance_of DateTime, user.created_at
      assert_instance_of DateTime, user.updated_at
      assert_equal MR::Factory.boolean, user.active

      user = subject.instance(:name => 'Test')
      assert_equal 'Test', user.name
    end

    should "allow specifying default fields when building the factory" do
      factory = MR::Factory::Model.new(User, FakeUserRecord, :name => nil, :active => false)

      user = factory.instance(:name => 'Test')
      assert_equal 'Test', user.name
      assert_equal false,  user.active
      assert_not_nil user.email

      fake_user = factory.fake(:active => true)
      assert_equal nil,  fake_user.name
      assert_equal true, fake_user.active
    end

  end

end
