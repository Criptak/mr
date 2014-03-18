require 'assert'
require 'mr/factory/record_stack'

require 'test/support/setup_test_db'
require 'test/support/models/comment'

class MR::Factory::RecordStack

  class SystemTests < DbTests
    desc "MR::Factory::RecordStack"
    setup do
      @comment_record = CommentRecord.new(:parent_type => 'UserRecord')
      @record_stack   = MR::Factory::RecordStack.new(@comment_record)
    end
    subject{ @record_stack }

    should "build an instance of the model with all " \
           "belongs to associations set" do
      assert_instance_of CommentRecord, @comment_record
      assert_true @comment_record.new_record?
      assert_instance_of UserRecord, @comment_record.parent
      assert_true @comment_record.parent.new_record?
      assert_instance_of AreaRecord, @comment_record.parent.area
      assert_true @comment_record.parent.area.new_record?
    end

    should "be able to create all the records and set foreign keys" do
      assert_nothing_raised{ subject.create }
      assert_false @comment_record.new_record?
      assert_false @comment_record.parent.new_record?
      assert_equal @comment_record.parent.id, @comment_record.parent_id
      assert_false @comment_record.parent.area.new_record?
      assert_equal @comment_record.parent.area_id, @comment_record.parent.area.id
    end

    should "be able to destroy all the records" do
      subject.create
      assert_nothing_raised{ subject.destroy }
      assert_true @comment_record.destroyed?
      assert_true @comment_record.parent.destroyed?
      assert_true @comment_record.parent.area.destroyed?
    end

  end

end
