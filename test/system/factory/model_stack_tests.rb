require 'assert'
require 'mr/factory/model_stack'

require 'test/support/setup_test_db'
require 'test/support/models/comment'

class MR::Factory::ModelStack

  class SystemTests < DbTests
    desc "MR::Factory::ModelStack"
    setup do
      @comment     = Comment.new(:parent_type => 'UserRecord')
      @model_stack = MR::Factory::ModelStack.new(@comment)
    end
    subject{ @model_stack }

    should have_readers :model

    should "build an instance of the model with all " \
           "belongs to associations set" do
      assert_instance_of Comment, @comment
      assert @comment.new?
      assert_instance_of User, @comment.parent
      assert @comment.parent.new?
      assert_instance_of Area, @comment.parent.area
      assert @comment.parent.area.new?
    end

  end

end
