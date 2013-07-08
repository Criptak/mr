require 'assert'
require 'mr/stack/record_stack'

require 'test/support/setup_test_db'
require 'test/support/models/comment_record'

class MR::Stack::RecordStack

  class BaseTests < Assert::Context
    desc "MR::Stack::RecordStack"
    setup do
      @record_stack = MR::Stack::RecordStack.new(CommentRecord)
    end
    teardown do
      @record_stack.destroy rescue nil
    end
    subject{ @record_stack }

    should have_readers :record
    should have_imeths :create, :destroy
    should have_imeths :create_dependencies, :destroy_dependencies

    should "build an instance of the record with " \
           "all belongs to associations set" do
      record = subject.record
      assert_instance_of CommentRecord, record
      assert record.new_record?
      assert_instance_of UserRecord, record.user
      assert record.user.new_record?
      assert_instance_of AreaRecord, record.user.area
      assert record.user.area.new_record?
    end

    should "create all the dependencies for the record with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      record = subject.record
      assert_not record.user.area.new_record?
      assert_not record.user.new_record?
      assert_equal record.user.area.id, record.user.area_id
      assert record.new_record?
      assert_equal record.user.id, record.user_id
    end

    should "remove all the dependencies for the record with #destroy_dependencies" do
      subject.create_dependencies
      record = subject.record
      assert_nothing_raised{ subject.destroy_dependencies }

      assert record.user.area.destroyed?
      assert record.user.destroyed?
      assert record.new_record?
    end

    should "create all the dependencies and the record with #create" do
      assert_nothing_raised{ subject.create }

      record = subject.record
      assert_not record.user.area.new_record?
      assert_not record.user.new_record?
      assert_equal record.user.area.id, record.user.area_id
      assert_not record.new_record?
      assert_equal record.user.id, record.user_id
    end

    should "remove all the dependencies and the record with #destroy" do
      subject.create
      record = subject.record
      assert_nothing_raised{ subject.destroy }

      assert record.user.area.destroyed?
      assert record.user.destroyed?
      assert record.destroyed?
    end

  end

end
