require 'assert'
require 'mr/factory/model_factory'

require 'test/support/setup_test_db'
require 'test/support/models/fake_user_record'
require 'test/support/models/user'
require 'test/support/models/user_record'

class MR::Factory::ModelFactory

  class BaseTests < Assert::Context
    desc "MR::Factory::Model"
    setup do
      @factory = MR::Factory::ModelFactory.new(User)
    end
    subject{ @factory }

    should have_imeths :instance, :fake

    should "build an instance of the model with the fake record class and "\
          "allow setting fields with #fake" do
      assert_raises(RuntimeError){ subject.fake }

      factory = MR::Factory::ModelFactory.new(User, FakeUserRecord)
      fake_user = factory.fake
      assert_instance_of User,           fake_user
      assert_instance_of FakeUserRecord, fake_user.send(:record)
      # should use the factory and default the column values
      assert_not_nil fake_user.name
      assert_not_nil fake_user.active
      assert_not_nil fake_user.email

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
      factory = MR::Factory::ModelFactory.new(User, FakeUserRecord, {
        :name   => nil,
        :active => false
      })
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
