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

  class FakeRecordTests < BaseTests
    desc "with a fake record"
    setup do
      @record_stack = MR::Stack::RecordStack.new(FakeCommentRecord)
    end
    teardown do
      @record_stack.destroy rescue nil
    end
    subject{ @record_stack }

    should "build an instance of the record with " \
           "all belongs to associations set" do
      record = subject.record
      assert_instance_of FakeCommentRecord, record
      assert record.new_record?
      assert_instance_of FakeUserRecord, record.user
      assert record.user.new_record?
      assert_instance_of FakeAreaRecord, record.user.area
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

  class StackRecordTests < Assert::Context
    desc "MR::Stack::Record"
    setup do
      @stack_record = MR::Stack::Record.new(UserRecord)
    end
    teardown do
      @stack_record.destroy rescue nil
    end
    subject{ @stack_record }

    should have_readers :instance, :associations
    should have_imeths :set_association, :create, :destroy

    should "build a record using MR::Factory with #instance" do
      record = subject.instance
      assert_instance_of UserRecord, record
      assert_not_nil record.name
      assert_not_nil record.email
      assert_not_nil record.active
    end

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
      stack_record = MR::Stack::Record.new(AreaRecord)
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

  class StackRecordAssociationTests < StackRecordTests
    desc "Association"
    setup do
      @association = MR::Stack::Record::Association.new(UserRecord, :user)
    end
    subject{ @association }

    should have_readers :record_class, :name
    should have_imeths :key

    should "know it's record class and name" do
      assert_equal UserRecord, subject.record_class
      assert_equal :user,      subject.name
    end

    should "return it's record class stringified with #key" do
      assert_equal 'UserRecord', subject.key
    end

  end

end
