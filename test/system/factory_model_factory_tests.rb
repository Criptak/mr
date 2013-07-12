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

    should have_imeths :instance, :instance_stack, :fake, :fake_stack
    should have_imeths :apply_args

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

    should "return a User stack with #instance_stack" do
      factory = MR::Factory::ModelFactory.new(User, {
        :name   => nil,
        :active => false
      })
      stack = factory.instance_stack(:name => 'Test')
      assert_instance_of MR::Stack::ModelStack, stack
      user = stack.model
      assert_instance_of User, user
      assert_equal 'Test', user.name
      assert_equal false,  user.active
      assert_not_nil user.email
    end

    should "return a fake User stack with #fake_stack" do
      factory = MR::Factory::ModelFactory.new(User, FakeUserRecord, {
        :name   => nil,
        :active => false
      })
      stack = factory.fake_stack(:name => 'Test')
      assert_instance_of MR::Stack::ModelStack, stack
      user = stack.model
      assert_instance_of User, user
      assert_instance_of FakeUserRecord, user.send(:record)
      assert_equal 'Test', user.name
      assert_equal false,  user.active
      assert_not_nil user.email
    end

    should "set the model's and it's association's attributes with #apply_args" do
      user = User.new.tap{ |record| record.area = Area.new }
      subject.apply_args(user, {
        :name   => 'Test',
        :active => false,
        :area   => { :name => 'Awesome' }
      })
      assert_equal 'Test',    user.name
      assert_equal false,     user.active
      assert_equal 'Awesome', user.area.name
    end

    should "automatically build association's with #apply_args" do
      user = User.new
      subject.apply_args(user, :area => { :name => 'Awesome' })
      assert_equal 'Awesome', user.area.name
    end

  end

end
