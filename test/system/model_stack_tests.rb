require 'assert'
require 'mr/model_stack'

require 'test/support/setup_test_db'
require 'test/support/models/comment'

class MR::ModelStack

  class SystemTests < DbTests
    desc "MR::ModelStack"
    setup do
      @comment     = Comment.new(:parent_type => 'UserRecord')
      @model_stack = MR::ModelStack.new(@comment)
    end
    subject{ @model_stack }

    should "build an instance of the model with all " \
           "belongs to associations set" do
      assert_instance_of Comment, @comment
      assert_true @comment.new?
      assert_instance_of User, @comment.parent
      assert_true @comment.parent.new?
      assert_instance_of Area, @comment.parent.area
      assert_true @comment.parent.area.new?
    end

  end

end
