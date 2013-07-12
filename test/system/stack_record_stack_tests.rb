require 'assert'
require 'mr/stack/record_stack'

require 'test/support/setup_test_db'
require 'test/support/models/area_record'
require 'test/support/models/comment_record'
require 'test/support/models/fake_comment_record'
require 'test/support/models/user_record'

class MR::Stack::RecordStack

  class BaseTests < Assert::Context
    desc "MR::Stack::RecordStack"
    setup do
      @comment_record = CommentRecord.new
      @record_stack = MR::Stack::RecordStack.new(@comment_record)
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
      assert_instance_of CommentRecord, @comment_record
      assert @comment_record.new_record?
      assert_instance_of UserRecord, @comment_record.user
      assert @comment_record.user.new_record?
      assert_instance_of AreaRecord, @comment_record.user.area
      assert @comment_record.user.area.new_record?
    end

    should "create all the dependencies for the record with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      assert_not @comment_record.user.area.new_record?
      assert_not @comment_record.user.new_record?
      assert_equal @comment_record.user.area.id, @comment_record.user.area_id
      assert @comment_record.new_record?
      assert_equal @comment_record.user.id, @comment_record.user_id
    end

    should "remove all the dependencies for the record with #destroy_dependencies" do
      subject.create_dependencies
      assert_nothing_raised{ subject.destroy_dependencies }

      assert @comment_record.user.area.destroyed?
      assert @comment_record.user.destroyed?
      assert @comment_record.new_record?
    end

    should "create all the dependencies and the record with #create" do
      assert_nothing_raised{ subject.create }

      assert_not @comment_record.user.area.new_record?
      assert_not @comment_record.user.new_record?
      assert_equal @comment_record.user.area.id, @comment_record.user.area_id
      assert_not @comment_record.new_record?
      assert_equal @comment_record.user.id, @comment_record.user_id
    end

    should "remove all the dependencies and the record with #destroy" do
      subject.create
      assert_nothing_raised{ subject.destroy }

      assert @comment_record.user.area.destroyed?
      assert @comment_record.user.destroyed?
      assert @comment_record.destroyed?
    end

  end

  class FakeRecordTests < BaseTests
    desc "with a fake record"
    setup do
      @fake_comment_record = FakeCommentRecord.new
      @record_stack = MR::Stack::RecordStack.new(@fake_comment_record)
    end
    teardown do
      @record_stack.destroy rescue nil
    end
    subject{ @record_stack }

    should "build an instance of the record with " \
           "all belongs to associations set" do
      assert_instance_of FakeCommentRecord, @fake_comment_record
      assert @fake_comment_record.new_record?
      assert_instance_of FakeUserRecord, @fake_comment_record.user
      assert @fake_comment_record.user.new_record?
      assert_instance_of FakeAreaRecord, @fake_comment_record.user.area
      assert @fake_comment_record.user.area.new_record?
    end

    should "create all the dependencies for the record with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      assert_not @fake_comment_record.user.area.new_record?
      assert_not @fake_comment_record.user.new_record?
      assert_equal @fake_comment_record.user.area.id, @fake_comment_record.user.area_id
      assert @fake_comment_record.new_record?
      assert_equal @fake_comment_record.user.id, @fake_comment_record.user_id
    end

    should "remove all the dependencies for the record with #destroy_dependencies" do
      subject.create_dependencies
      assert_nothing_raised{ subject.destroy_dependencies }

      assert @fake_comment_record.user.area.destroyed?
      assert @fake_comment_record.user.destroyed?
      assert @fake_comment_record.new_record?
    end

    should "create all the dependencies and the record with #create" do
      assert_nothing_raised{ subject.create }

      assert_not @fake_comment_record.user.area.new_record?
      assert_not @fake_comment_record.user.new_record?
      assert_equal @fake_comment_record.user.area.id, @fake_comment_record.user.area_id
      assert_not @fake_comment_record.new_record?
      assert_equal @fake_comment_record.user.id, @fake_comment_record.user_id
    end

    should "remove all the dependencies and the record with #destroy" do
      subject.create
      assert_nothing_raised{ subject.destroy }

      assert @fake_comment_record.user.area.destroyed?
      assert @fake_comment_record.user.destroyed?
      assert @fake_comment_record.destroyed?
    end

  end

  class StackRecordTests < Assert::Context
    desc "MR::Stack::Record"
    setup do
      @user_record  = UserRecord.new(:name => 'test')
      @stack_record = MR::Stack::Record.new(@user_record)
    end
    teardown do
      @stack_record.destroy rescue nil
    end
    subject{ @stack_record }

    should have_readers :instance, :associations
    should have_imeths :set_association, :create, :destroy

    should "build a list of association objects " \
           "for every ActiveRecord belongs to association" do
      associations = subject.associations
      assert_equal 1, associations.size

      association = associations.first
      assert_instance_of MR::Stack::Record::Association, association
      assert_equal AreaRecord, association.record_class
      assert_equal :area,      association.name
    end

    should "set the record's association given another Record with #set_association" do
      stack_record = MR::Stack::Record.new(AreaRecord.new)
      assert_nothing_raised{ subject.set_association(:area, stack_record) }
      assert_equal stack_record.instance, subject.instance.area
    end

    should "create the record with #create" do
      assert subject.instance.new_record?
      assert_nothing_raised{ subject.create }
      assert_not subject.instance.new_record?
    end

    should "destroy the record with #destroy" do
      subject.create
      assert_not subject.instance.new_record?
      assert_nothing_raised{ subject.destroy }
      assert subject.instance.destroyed?
    end

  end

end
