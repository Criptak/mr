require 'assert'
require 'mr/factory/model_factory'

require 'test/support/setup_test_db'
require 'test/support/models/area'
require 'test/support/models/comment'
require 'test/support/models/image'
require 'test/support/models/user'

class MR::Factory::ModelFactory

  class SystemTests < DbTests
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
      assert_equal({ 'test' => true }, subject.default_args)
    end

    should "allow reading and writing default instance args " \
           "with #default_instance_args" do
      subject.default_instance_args(:test => true)
      assert_equal({ 'test' => true }, subject.default_instance_args)
    end

    should "allow reading and writing default instance args " \
           "with #default_fake_args" do
      subject.default_fake_args(:test => true)
      assert_equal({ 'test' => true }, subject.default_fake_args)
    end

    should "allow passing a block when it's initialized" do
      factory = MR::Factory::ModelFactory.new(User) do
        default_args :test => true
        default_instance_args :instance => true
        default_fake_args :fake => true
      end
      assert_equal({ 'test' => true }, factory.default_args)
      assert_equal({ 'instance' => true }, factory.default_instance_args)
      assert_equal({ 'fake' => true }, factory.default_fake_args)
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
      user = User.new.tap do |u|
        u.area  = Area.new
        u.image = Image.new
      end
      subject.apply_args(user, {
        :area  => { :name => 'Test' },
        :image => { :file_path => 'test' }
      })
      assert_equal 'Test', user.area.name
      assert_equal 'test', user.image.file_path

      comment = Comment.new.tap{ |c| c.parent = User.new }
      subject.apply_args(comment, :parent => { :name => 'Test' })
      assert_equal 'Test', comment.parent.name
    end

    should "build and apply args to an associated model with #apply_args" do
      user = User.new
      subject.apply_args(user, {
        :area  => { :name => 'Test' },
        :image => { :file_path => 'test' }
      })
      assert_equal 'Test', user.area.name
      assert_equal 'test', user.image.file_path

      comment = Comment.new.tap{ |c| c.parent_type = 'UserRecord' }
      subject.apply_args(comment, :parent => { :name => 'Test' })
      assert_equal 'Test', comment.parent.name
    end

    should "raise an exception when building a polymorphic model with #apply_args" do
      comment = Comment.new
      assert_raises(NoRecordClassError) do
        subject.apply_args(comment, :parent => { :name => 'Test' })
      end
    end

    should "build an instance of the model with it's fields set, " \
           "using #instance" do
      user = subject.instance
      assert_instance_of User,       user
      assert_instance_of UserRecord, user.send(:record)
      assert user.new?
      assert_kind_of String,     user.name
      assert_kind_of Integer,    user.number
      assert_kind_of BigDecimal, user.salary
      assert_kind_of Date,       user.started_on
    end

    should "build an instance stack for the model with it's fields set, " \
           "using #instance_stack" do
      stack = subject.instance_stack
      assert_instance_of MR::Factory::ModelStack, stack
      user = stack.model
      assert_instance_of User,       user
      assert_instance_of UserRecord, user.send(:record)
      assert user.new?
      assert_kind_of String,     user.name
      assert_kind_of Integer,    user.number
      assert_kind_of BigDecimal, user.salary
      assert_kind_of Date,       user.started_on
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

  class WithAFakeRecordClassTests < SystemTests
    desc "with a fake record class"
    setup do
      @factory = MR::Factory::ModelFactory.new(User, FakeUserRecord)
    end
    subject{ @factory }

    should "build a fake of the model with it's fields set, " \
           "using #fake" do
      user = subject.fake
      assert_instance_of User,           user
      assert_instance_of FakeUserRecord, user.send(:record)
      assert user.new?
      assert_kind_of String,  user.name
      assert_kind_of Integer, user.number
      assert_kind_of Float,   user.salary
      assert_kind_of Date,    user.started_on
    end

    should "build a fake stack for the model with it's fields set, " \
           "using #fake_stack" do
      stack = subject.fake_stack
      assert_instance_of MR::Factory::ModelStack, stack
      user = stack.model
      assert_instance_of User,           user
      assert_instance_of FakeUserRecord, user.send(:record)
      assert user.new?
      assert_kind_of String,  user.name
      assert_kind_of Integer, user.number
      assert_kind_of Float,   user.salary
      assert_kind_of Date,    user.started_on
    end

    should "allow applying hash args to an associated model with #apply_args" do
      user = User.new(FakeUserRecord.new).tap do |u|
        u.area  = Area.new(FakeAreaRecord.new)
        u.image = Image.new(FakeImageRecord.new)
      end
      subject.apply_args(user, {
        :area  => { :name => 'Test' },
        :image => { :file_path => 'test' }
      })
      assert_equal 'Test', user.area.name
      assert_equal 'test', user.image.file_path

      comment = Comment.new(FakeCommentRecord.new).tap do |c|
        c.parent = User.new(FakeUserRecord.new)
      end
      subject.apply_args(comment, :parent => { :name => 'Test' })
      assert_equal 'Test', comment.parent.name
    end

    should "build and apply args to an associated model with #apply_args" do
      user = User.new(FakeUserRecord.new)
      subject.apply_args(user, {
        :area => { :name => 'Test' },
        :image => { :file_path => 'test' }
      })
      assert_equal 'Test', user.area.name
      assert_equal 'test', user.image.file_path

      comment = Comment.new(FakeCommentRecord.new).tap do |c|
        c.parent_type = 'FakeUserRecord'
      end
      subject.apply_args(comment, :parent => { :name => 'Test' })
      assert_equal 'Test', comment.parent.name
    end

    should "raise an exception when building a polymorphic model with #apply_args" do
      comment = Comment.new(FakeCommentRecord.new)
      assert_raises(NoRecordClassError) do
        subject.apply_args(comment, :parent => { :name => 'Test' })
      end
    end

  end

  class WithDefaultArgsTests < SystemTests
    desc "with default args"
    setup do
      @factory = MR::Factory::ModelFactory.new(User, FakeUserRecord) do
        default_args({
          :name   => 'Test',
          :number => 12345
        })
      end
    end

    should "use the default args with #apply_args" do
      user = User.new
      subject.apply_args(user)
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

    should "use the default args with #instance" do
      user = subject.instance
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

    should "use the default args with #instance_stack" do
      stack = subject.instance_stack
      user  = stack.model
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

    should "use the default args with #fake" do
      user = subject.fake
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

    should "use the default args with #fake_stack" do
      stack = subject.fake_stack
      user  = stack.model
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

    should "allow overwriting the defaults by passing args to #apply_args" do
      user = User.new
      subject.apply_args(user, :name => 'Not Test')
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
    end

    should "allow overwriting the defaults by passing args to #instance" do
      user = subject.instance(:name => 'Not Test')
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
    end

    should "allow overwriting the defaults by passing args to #instance_stack" do
      stack = subject.instance_stack(:name => 'Not Test')
      user  = stack.model
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
    end

    should "allow overwriting the defaults by passing args to #fake" do
      user = subject.fake(:name => 'Not Test')
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
    end

    should "allow overwriting the defaults by passing args to #fake_stack" do
      stack = subject.fake_stack(:name => 'Not Test')
      user  = stack.model
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
    end

  end

  class WithDefaultInstanceArgsTests < SystemTests
    desc "with default instance args"
    setup do
      @factory = MR::Factory::ModelFactory.new(User, FakeUserRecord) do
        default_args({
          :name   => 'Test',
          :number => 12345
        })
        default_instance_args({
          :name   => 'Instance Test',
          :salary => 2.5
        })
      end
    end

    should "use the default args with #instance" do
      user = subject.instance
      assert_equal 'Instance Test', user.name
      assert_equal 12345,           user.number
      assert_equal 2.5,             user.salary
    end

    should "use the default args with #instance_stack" do
      stack = subject.instance_stack
      user  = stack.model
      assert_equal 'Instance Test', user.name
      assert_equal 12345,           user.number
      assert_equal 2.5,             user.salary
    end

    should "allow overwriting the defaults by passing args to #instance" do
      user = subject.instance(:name => 'Not Test')
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
      assert_equal 2.5,        user.salary
    end

    should "allow overwriting the defaults by passing args to #instance_stack" do
      stack = subject.instance_stack(:name => 'Not Test')
      user  = stack.model
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
      assert_equal 2.5,        user.salary
    end

    should "not use the default args with #fake" do
      user = subject.fake
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

    should "not use the default args with #fake_stack" do
      stack = subject.fake_stack
      user  = stack.model
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

  end

  class WithDefaultFakeArgsTests < SystemTests
    desc "with default fake args"
    setup do
      @factory = MR::Factory::ModelFactory.new(User, FakeUserRecord) do
        default_args({
          :name   => 'Test',
          :number => 12345
        })
        default_fake_args({
          :name   => 'Fake Test',
          :salary => 2.5
        })
      end
    end

    should "use the default args with #fake" do
      user = subject.fake
      assert_equal 'Fake Test', user.name
      assert_equal 12345,       user.number
      assert_equal 2.5,         user.salary
    end

    should "use the default args with #fake_stack" do
      stack = subject.fake_stack
      user  = stack.model
      assert_equal 'Fake Test', user.name
      assert_equal 12345,       user.number
      assert_equal 2.5,         user.salary
    end

    should "allow overwriting the defaults by passing args to #fake" do
      user = subject.fake(:name => 'Not Test')
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
      assert_equal 2.5,        user.salary
    end

    should "allow overwriting the defaults by passing args to #fake_stack" do
      stack = subject.fake_stack(:name => 'Not Test')
      user  = stack.model
      assert_equal 'Not Test', user.name
      assert_equal 12345,      user.number
      assert_equal 2.5,        user.salary
    end

    should "not use the default args with #instance" do
      user = subject.instance
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

    should "not use the default args with #instance_stack" do
      stack = subject.instance_stack
      user  = stack.model
      assert_equal 'Test', user.name
      assert_equal 12345,  user.number
    end

  end

  class DeepMergeTests < SystemTests
    desc "with deeply nested args"
    setup do
      @factory = MR::Factory::ModelFactory.new(Image, FakeImageRecord) do
        default_args :user => { :name => 'Test' }
        default_instance_args :user => { :number => 12345 }
        default_fake_args     :user => { :number => 54321 }
      end
    end

    should "deeply merge the args preserving both the defaults and " \
           "what was passed when applying args with an instance" do
      image = @factory.instance({
        :user => { :area => { :name => 'Amazing' } }
      })
      user = image.user
      assert_equal 'Test',    user.name
      assert_equal 12345,     user.number
      assert_equal 'Amazing', user.area.name
    end

    should "deeply merge the args preserving both the defaults and " \
           "what was passed when applying args with a fake" do
      image = @factory.fake({
        :user => { :area => { :name => 'Amazing' } }
      })
      user = image.user
      assert_equal 'Test',    user.name
      assert_equal 54321,     user.number
      assert_equal 'Amazing', user.area.name
    end

  end

  class DupArgsTests < SystemTests
    desc "using a factory multiple times"
    setup do
      @factory = MR::Factory::ModelFactory.new(Image) do
        default_args :user => { :area => { :name => 'Test' } }
      end
    end

    should "not alter the defaults hash when applying args" do
      assert_equal 'Test', @factory.instance.user.area.name
      assert_equal 'Test', @factory.instance.user.area.name
    end

  end

end
