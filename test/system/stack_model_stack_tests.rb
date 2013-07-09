require 'assert'
require 'mr/stack/model_stack'

require 'test/support/setup_test_db'
require 'test/support/models/comment'
require 'test/support/models/fake_comment_record'

class MR::Stack::ModelStack

  class BaseTests < Assert::Context
    desc "MR::Stack::ModelStack"
    setup do
      @model_stack = MR::Stack::ModelStack.new(Comment)
    end
    teardown do
      @model_stack.destroy rescue nil
    end
    subject{ @model_stack }

    should have_readers :model

    should "build an instance of the model with " \
           "all belongs to associations set" do
      model = subject.model
      assert_instance_of Comment, model
      assert model.new?
      assert_instance_of User, model.user
      assert model.user.new?
      assert_instance_of Area, model.user.area
      assert model.user.area.new?
    end

    should "create all the dependencies for the model with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      model = subject.model
      assert_not model.user.area.new?
      assert_not model.user.new?
      assert_equal model.user.area.id, model.user.area_id
      assert model.new?
      assert_equal model.user.id, model.user_id
    end

    should "remove all the dependencies for the model with #destroy_dependencies" do
      subject.create_dependencies
      model = subject.model
      assert_nothing_raised{ subject.destroy_dependencies }

      assert model.user.area.destroyed?
      assert model.user.destroyed?
      assert model.new?
    end

    should "create all the dependencies and the model with #create" do
      assert_nothing_raised{ subject.create }

      model = subject.model
      assert_not model.user.area.new?
      assert_not model.user.new?
      assert_equal model.user.area.id, model.user.area_id
      assert_not model.new?
      assert_equal model.user.id, model.user_id
    end

    should "remove all the dependencies and the model with #destroy" do
      subject.create
      model = subject.model
      assert_nothing_raised{ subject.destroy }

      assert model.user.area.destroyed?
      assert model.user.destroyed?
      assert model.destroyed?
    end

  end

  class FakeModelTests < BaseTests
    desc "with a fake record"
    setup do
      @model_stack = MR::Stack::ModelStack.new(Comment, FakeCommentRecord)
    end
    teardown do
      @model_stack.destroy rescue nil
    end
    subject{ @model_stack }

    should "build an instance of the model with " \
           "all belongs to associations set" do
      model = subject.model
      assert_instance_of Comment, model
      assert model.new?
      assert_instance_of FakeCommentRecord, model.send(:record)
      assert_instance_of User, model.user
      assert model.user.new?
      assert_instance_of FakeUserRecord, model.user.send(:record)
      assert_instance_of Area, model.user.area
      assert model.user.area.new?
      assert_instance_of FakeAreaRecord, model.user.area.send(:record)
    end

    should "create all the dependencies for the model with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      model = subject.model
      assert_not model.user.area.new?
      assert_not model.user.new?
      assert_equal model.user.area.id, model.user.area_id
      assert model.new?
      assert_equal model.user.id, model.user_id
    end

    should "remove all the dependencies for the model with #destroy_dependencies" do
      subject.create_dependencies
      model = subject.model
      assert_nothing_raised{ subject.destroy_dependencies }

      assert model.user.area.destroyed?
      assert model.user.destroyed?
      assert model.new?
    end

    should "create all the dependencies and the model with #create" do
      assert_nothing_raised{ subject.create }

      model = subject.model
      assert_not model.user.area.new?
      assert_not model.user.new?
      assert_equal model.user.area.id, model.user.area_id
      assert_not model.new?
      assert_equal model.user.id, model.user_id
    end

    should "remove all the dependencies and the model with #destroy" do
      subject.create
      model = subject.model
      assert_nothing_raised{ subject.destroy }

      assert model.user.area.destroyed?
      assert model.user.destroyed?
      assert model.destroyed?
    end

  end

end
