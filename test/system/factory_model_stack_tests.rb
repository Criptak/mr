require 'assert'
require 'mr/factory/model_stack'

require 'test/support/setup_test_db'
require 'test/support/models/comment'

class MR::Factory::ModelStack

  class SystemTests < Assert::Context
    desc "MR::Factory::ModelStack"
    setup do
      @comment     = Comment.new(:parent_type => 'UserRecord')
      @model_stack = MR::Factory::ModelStack.new(@comment)
    end
    teardown do
      @model_stack.destroy rescue nil
    end
    subject{ @model_stack }

    should have_readers :model

    should "build an instance of the model with " \
           "all belongs to associations set" do
      assert_instance_of Comment, @comment
      assert @comment.new?
      assert_instance_of User, @comment.parent
      assert @comment.parent.new?
      assert_instance_of Area, @comment.parent.area
      assert @comment.parent.area.new?
    end

    should "create all the dependencies for the model with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      assert_not @comment.parent.new?
      assert_equal @comment.parent.id, @comment.parent_id
      assert_not @comment.parent.area.new?
      assert_equal @comment.parent.area.id, @comment.parent.area_id
      assert @comment.new?
    end

    should "remove all the dependencies for the model with #destroy_dependencies" do
      subject.create_dependencies
      assert_nothing_raised{ subject.destroy_dependencies }

      assert @comment.parent.destroyed?
      assert @comment.parent.area.destroyed?
      assert @comment.new?
    end

    should "create all the dependencies and the model with #create" do
      assert_nothing_raised{ subject.create }

      assert_not @comment.parent.new?
      assert_equal @comment.parent.id, @comment.parent_id
      assert_not @comment.parent.area.new?
      assert_equal @comment.parent.area.id, @comment.parent.area_id
      assert_not @comment.new?
    end

    should "remove all the dependencies and the model with #destroy" do
      subject.create
      assert_nothing_raised{ subject.destroy }

      assert @comment.parent.destroyed?
      assert @comment.parent.area.destroyed?
      assert @comment.destroyed?
    end

  end

  class FakeModelTests < SystemTests
    desc "with a fake record"
    setup do
      @fake_comment = Comment.new(FakeCommentRecord.new, {
        :parent_type => 'FakeUserRecord'
      })
      @model_stack  = MR::Factory::ModelStack.new(@fake_comment)
    end
    teardown do
      @model_stack.destroy rescue nil
    end
    subject{ @model_stack }

    should "build an instance of the model with " \
           "all belongs to associations set" do
      assert_instance_of Comment, @fake_comment
      assert @fake_comment.new?
      assert_instance_of FakeCommentRecord, @fake_comment.send(:record)
      assert_instance_of User, @fake_comment.parent
      assert @fake_comment.parent.new?
      assert_instance_of FakeUserRecord, @fake_comment.parent.send(:record)
      assert_instance_of Area, @fake_comment.parent.area
      assert @fake_comment.parent.area.new?
      assert_instance_of FakeAreaRecord, @fake_comment.parent.area.send(:record)
    end

    should "create all the dependencies for the model with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      assert_not @fake_comment.parent.new?
      assert_equal @fake_comment.parent.id, @fake_comment.parent_id
      assert_not @fake_comment.parent.area.new?
      assert_equal @fake_comment.parent.area.id, @fake_comment.parent.area_id
      assert @fake_comment.new?
    end

    should "remove all the dependencies for the model with #destroy_dependencies" do
      subject.create_dependencies
      assert_nothing_raised{ subject.destroy_dependencies }

      assert @fake_comment.parent.destroyed?
      assert @fake_comment.parent.area.destroyed?
      assert @fake_comment.new?
    end

    should "create all the dependencies and the model with #create" do
      assert_nothing_raised{ subject.create }

      assert_not @fake_comment.parent.new?
      assert_equal @fake_comment.parent.id, @fake_comment.parent_id
      assert_not @fake_comment.parent.area.new?
      assert_equal @fake_comment.parent.area.id, @fake_comment.parent.area_id
      assert_not @fake_comment.new?
    end

    should "remove all the dependencies and the model with #destroy" do
      subject.create
      assert_nothing_raised{ subject.destroy }

      assert @fake_comment.parent.destroyed?
      assert @fake_comment.parent.area.destroyed?
      assert @fake_comment.destroyed?
    end

  end

end
