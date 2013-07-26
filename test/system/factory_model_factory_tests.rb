require 'assert'
require 'mr/factory/model_factory'

require 'test/support/setup_test_db'
require 'test/support/models/comment'
require 'test/support/models/fake_user_record'
require 'test/support/models/fake_comment_record'
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
    should have_imeths :default_args, :default_instance_args, :default_fake_args

    should "allow reading and writing default args with #default_args" do
      subject.default_args(:test => true)
      assert_equal({ :test => true }, subject.default_args)
    end

    should "allow reading and writing default instance args " \
           "with #default_instance_args" do
      subject.default_instance_args(:test => true)
      assert_equal({ :test => true }, subject.default_instance_args)
    end

    should "allow reading and writing default instance args " \
           "with #default_fake_args" do
      subject.default_fake_args(:test => true)
      assert_equal({ :test => true }, subject.default_fake_args)
    end

    should "allow passing a block when it's initialized" do
      factory = MR::Factory::ModelFactory.new(User) do
        default_args :test => true
        default_instance_args :instance => true
        default_fake_args :fake => true
      end
      assert_equal({ :test => true }, factory.default_args)
      assert_equal({ :instance => true }, factory.default_instance_args)
      assert_equal({ :fake => true }, factory.default_fake_args)
    end

    should "allow applying hash args to a model with #apply_args" do
      user = User.new
      subject.apply_args(user, :name => 'Test')
      assert_equal 'Test', user.name
    end

    should "allow applying proc values to a model with #apply_args" do
      area_factory = MR::Factory::ModelFactory.new(Area)
      args = { :area => proc{ area_factory.instance } }
      user = User.new
      subject.apply_args(user, args)
      assert_instance_of Area, user.area
      other_user = User.new
      subject.apply_args(other_user, args)
      assert_instance_of Area, other_user.area
      assert_not_same user.area, other_user.area
    end

    should "allow applying hash args to an associated model with #apply_args" do
      user = User.new.tap{ |u| u.area = Area.new }
      subject.apply_args(user, :area => { :name => 'Test' })
      assert_equal 'Test', user.area.name
    end

    should "build and apply args to an associated model with #apply_args" do
      user = User.new
      subject.apply_args(user, :area => { :name => 'Test' })
      assert_equal 'Test', user.area.name
    end

    should "build an instance of the model with it's fields set, " \
           "using #instance" do
      user = subject.instance
      assert_instance_of User,       user
      assert_instance_of UserRecord, user.send(:record)
      assert user.new?
      assert_instance_of String,   user.name
      assert_instance_of String,   user.email
      assert_instance_of DateTime, user.created_at
      assert_instance_of DateTime, user.updated_at
      assert_equal MR::Factory.boolean, user.active
    end

    should "build an instance stack for the model with it's fields set, " \
           "using #instance_stack" do
      stack = subject.instance_stack
      assert_instance_of MR::Factory::ModelStack, stack
      user = stack.model
      assert_instance_of User,       user
      assert_instance_of UserRecord, user.send(:record)
      assert user.new?
      assert_instance_of String,   user.name
      assert_instance_of String,   user.email
      assert_instance_of DateTime, user.created_at
      assert_instance_of DateTime, user.updated_at
      assert_equal MR::Factory.boolean, user.active
    end

    should "raise an exception about missing a fake record class with #fake" do
      exception = nil
      begin; subject.fake; rescue Exception => exception; end
      assert_equal RuntimeError, exception.class
      expected_message = "A fake_record_class wasn't provided"
      assert_equal expected_message, exception.message
    end

    should "raise an exception about missing a fake record class " \
           "with #fake_stack" do
      exception = nil
      begin; subject.fake_stack; rescue Exception => exception; end
      assert_equal RuntimeError, exception.class
      expected_message = "A fake_record_class wasn't provided"
      assert_equal expected_message, exception.message
    end

  end

  class WithAFakeRecordClassTests < BaseTests
    desc "with a fake record class"
    setup do
      @factory = MR::Factory::ModelFactory.new(User, FakeUserRecord)
    end
    subject{ @factory }

    should "build a fake of the model with it's fields set, " \
           "using #fake" do
      user = subject.fake
      assert_instance_of User,       user
      assert_instance_of FakeUserRecord, user.send(:record)
      assert user.new?
      assert_instance_of String,   user.name
      assert_instance_of String,   user.email
      assert_instance_of DateTime, user.created_at
      assert_instance_of DateTime, user.updated_at
      assert_equal MR::Factory.boolean, user.active
    end

    should "build a fake stack for the model with it's fields set, " \
           "using #fake_stack" do
      stack = subject.fake_stack
      assert_instance_of MR::Factory::ModelStack, stack
      user = stack.model
      assert_instance_of User,       user
      assert_instance_of FakeUserRecord, user.send(:record)
      assert user.new?
      assert_instance_of String,   user.name
      assert_instance_of String,   user.email
      assert_instance_of DateTime, user.created_at
      assert_instance_of DateTime, user.updated_at
      assert_equal MR::Factory.boolean, user.active
    end

  end

  class WithDefaultArgsTests < BaseTests
    desc "with default args"
    setup do
      @factory = MR::Factory::ModelFactory.new(User, FakeUserRecord) do
        default_args({
          :name   => 'Test',
          :email  => 'test@example.com',
          :active => true
        })
      end
    end

    should "use the default args with #apply_args" do
      user = User.new
      subject.apply_args(user)
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "use the default args with #instance" do
      user = subject.instance
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "use the default args with #instance_stack" do
      stack = subject.instance_stack
      user  = stack.model
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "use the default args with #fake" do
      user = subject.fake
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "use the default args with #fake_stack" do
      stack = subject.fake_stack
      user  = stack.model
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #apply_args" do
      user = User.new
      subject.apply_args(user, :name => 'Not Test')
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #instance" do
      user = subject.instance(:name => 'Not Test')
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #instance_stack" do
      stack = subject.instance_stack(:name => 'Not Test')
      user  = stack.model
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #fake" do
      user = subject.fake(:name => 'Not Test')
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #fake_stack" do
      stack = subject.fake_stack(:name => 'Not Test')
      user  = stack.model
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

  end

  class WithDefaultInstanceArgsTests < BaseTests
    desc "with default instance args"
    setup do
      @factory = MR::Factory::ModelFactory.new(User, FakeUserRecord) do
        default_args({
          :name   => 'Test',
          :email  => 'test@example.com'
        })
        default_instance_args({
          :name   => 'Instance Test',
          :active => true
        })
      end
    end

    should "use the default args with #instance" do
      user = subject.instance
      assert_equal 'Instance Test',    user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "use the default args with #instance_stack" do
      stack = subject.instance_stack
      user  = stack.model
      assert_equal 'Instance Test',    user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #instance" do
      user = subject.instance(:name => 'Not Test')
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #instance_stack" do
      stack = subject.instance_stack(:name => 'Not Test')
      user  = stack.model
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "not use the default args with #fake" do
      user = subject.fake
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
    end

    should "not use the default args with #fake_stack" do
      stack = subject.fake_stack
      user  = stack.model
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
    end

  end

  class WithDefaultFakeArgsTests < BaseTests
    desc "with default fake args"
    setup do
      @factory = MR::Factory::ModelFactory.new(User, FakeUserRecord) do
        default_args({
          :name   => 'Test',
          :email  => 'test@example.com'
        })
        default_fake_args({
          :name   => 'Fake Test',
          :active => true
        })
      end
    end

    should "use the default args with #fake" do
      user = subject.fake
      assert_equal 'Fake Test',        user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "use the default args with #fake_stack" do
      stack = subject.fake_stack
      user  = stack.model
      assert_equal 'Fake Test',        user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #fake" do
      user = subject.fake(:name => 'Not Test')
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "allow overwriting the defaults by passing args to #fake_stack" do
      stack = subject.fake_stack(:name => 'Not Test')
      user  = stack.model
      assert_equal 'Not Test',         user.name
      assert_equal 'test@example.com', user.email
      assert_equal true,               user.active
    end

    should "not use the default args with #instance" do
      user = subject.instance
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
    end

    should "not use the default args with #instance_stack" do
      stack = subject.instance_stack
      user  = stack.model
      assert_equal 'Test',             user.name
      assert_equal 'test@example.com', user.email
    end

  end

  class DeepMergeTests < BaseTests
    desc "with deeply nested args"
    setup do
      @factory = MR::Factory::ModelFactory.new(Comment, FakeCommentRecord) do
        default_args :user => { :name => 'Test' }
        default_instance_args :user => { :email => 'instance@example.com' }
        default_fake_args     :user => { :email => 'fake@example.com' }
      end
    end

    should "deeply merge the args preserving both the defaults and " \
           "what was passed when applying args with an instance" do
      comment = @factory.instance({
        :user => { :area => { :name => 'Amazing' } }
      })
      user = comment.user
      assert_equal 'Test',             user.name
      assert_equal 'instance@example.com', user.email
      assert_equal 'Amazing',          user.area.name
    end

    should "deeply merge the args preserving both the defaults and " \
           "what was passed when applying args with a fake" do
      comment = @factory.fake({
        :user => { :area => { :name => 'Amazing' } }
      })
      user = comment.user
      assert_equal 'Test',             user.name
      assert_equal 'fake@example.com', user.email
      assert_equal 'Amazing',          user.area.name
    end

  end

  class DupArgsTests < BaseTests
    desc "using a factory multiple times"
    setup do
      @factory = MR::Factory::ModelFactory.new(Comment) do
        default_args :user => { :area => { :name => 'Test' } }
      end
    end

    should "not alter the defaults hash when applying args" do
      assert_equal 'Test', @factory.instance.user.area.name
      assert_equal 'Test', @factory.instance.user.area.name
    end

  end

end
