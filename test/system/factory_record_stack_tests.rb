require 'assert'
require 'mr/factory/record_stack'

require 'test/support/setup_test_db'
require 'test/support/models/area'
require 'test/support/models/comment'
require 'test/support/models/user'

class MR::Factory::RecordStack

  class SystemTests < DbTests
    desc "MR::Factory::RecordStack"
    setup do
      @comment_record = CommentRecord.new(:parent_type => 'UserRecord')
      @record_stack = MR::Factory::RecordStack.new(@comment_record)
    end
    subject{ @record_stack }

    should have_readers :record
    should have_imeths :create, :destroy
    should have_imeths :create_dependencies, :destroy_dependencies

    should "build an instance of the record with " \
           "all belongs to associations set" do
      assert_instance_of CommentRecord, @comment_record
      assert @comment_record.new_record?
      assert_instance_of UserRecord, @comment_record.parent
      assert @comment_record.parent.new_record?
      assert_instance_of AreaRecord, @comment_record.parent.area
      assert @comment_record.parent.area.new_record?
    end

    should "create all the dependencies for the record with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      assert_not @comment_record.parent.new_record?
      assert_equal @comment_record.parent.id, @comment_record.parent_id
      assert_not @comment_record.parent.area.new_record?
      assert_equal @comment_record.parent.area.id, @comment_record.parent.area_id
      assert @comment_record.new_record?
    end

    should "remove all the dependencies for the record with #destroy_dependencies" do
      subject.create_dependencies
      assert_nothing_raised{ subject.destroy_dependencies }

      assert @comment_record.parent.destroyed?
      assert @comment_record.parent.area.destroyed?
      assert @comment_record.new_record?
    end

    should "create all the dependencies and the record with #create" do
      assert_nothing_raised{ subject.create }

      assert_not @comment_record.parent.new_record?
      assert_equal @comment_record.parent.id, @comment_record.parent_id
      assert_not @comment_record.parent.area.new_record?
      assert_equal @comment_record.parent.area.id, @comment_record.parent.area_id
      assert_not @comment_record.new_record?
    end

    should "remove all the dependencies and the record with #destroy" do
      subject.create
      assert_nothing_raised{ subject.destroy }

      assert @comment_record.parent.destroyed?
      assert @comment_record.parent.area.destroyed?
      assert @comment_record.destroyed?
    end

  end

  class FakeRecordTests < SystemTests
    desc "with a fake record"
    setup do
      @fake_comment_record = FakeCommentRecord.new(:parent_type => 'FakeUserRecord')
      @record_stack = MR::Factory::RecordStack.new(@fake_comment_record)
    end
    subject{ @record_stack }

    should "build an instance of the record with " \
           "all belongs to associations set" do
      assert_instance_of FakeCommentRecord, @fake_comment_record
      assert @fake_comment_record.new_record?
      assert_instance_of FakeUserRecord, @fake_comment_record.parent
      assert @fake_comment_record.parent.new_record?
      assert_instance_of FakeAreaRecord, @fake_comment_record.parent.area
      assert @fake_comment_record.parent.area.new_record?
    end

    should "create all the dependencies for the record with #create_dependencies" do
      assert_nothing_raised{ subject.create_dependencies }

      assert_not @fake_comment_record.parent.new_record?
      assert_equal @fake_comment_record.parent.id, @fake_comment_record.parent_id
      assert_not @fake_comment_record.parent.area.new_record?
      assert_equal @fake_comment_record.parent.area.id, @fake_comment_record.parent.area_id
      assert @fake_comment_record.new_record?
    end

    should "remove all the dependencies for the record with #destroy_dependencies" do
      subject.create_dependencies
      assert_nothing_raised{ subject.destroy_dependencies }

      assert @fake_comment_record.parent.destroyed?
      assert @fake_comment_record.parent.area.destroyed?
      assert @fake_comment_record.new_record?
    end

    should "create all the dependencies and the record with #create" do
      assert_nothing_raised{ subject.create }

      assert_not @fake_comment_record.parent.new_record?
      assert_equal @fake_comment_record.parent.id, @fake_comment_record.parent_id
      assert_not @fake_comment_record.parent.area.new_record?
      assert_equal @fake_comment_record.parent.area.id, @fake_comment_record.parent.area_id
      assert_not @fake_comment_record.new_record?
    end

    should "remove all the dependencies and the record with #destroy" do
      subject.create
      assert_nothing_raised{ subject.destroy }

      assert @fake_comment_record.parent.destroyed?
      assert @fake_comment_record.parent.area.destroyed?
      assert @fake_comment_record.destroyed?
    end

  end

  class PresetAssociationsTests < SystemTests
    desc "when provided preset associations"
    setup do
      @user_record    = UserRecord.new.tap{ |u| u.save! }
      @comment_record = CommentRecord.new(:parent => @user_record)
      @record_stack = MR::Factory::RecordStack.new(@comment_record)
    end

    should "use a preset association for other cases of the record class" do
      assert_same @user_record, @comment_record.parent
      assert_same @user_record, @comment_record.created_by
    end

    should "always use the preset value for the association" do
      created_by_record = UserRecord.new.tap{ |u| u.save }
      comment_record    = CommentRecord.new({
        :parent     => @user_record,
        :created_by => created_by_record
      })
      MR::Factory::RecordStack.new(comment_record)

      assert_not_same created_by_record, @user_record
      assert_same @user_record,      comment_record.parent
      assert_same created_by_record, comment_record.created_by
    end

  end

  class StackRecordTests < DbTests
    desc "MR::Factory::Record"
    setup do
      @user_record  = UserRecord.new(:name => 'test')
      @stack_record = MR::Factory::Record.new(@user_record)
    end
    subject{ @stack_record }

    should have_readers :instance, :associations
    should have_imeths :set_association, :create, :destroy, :refresh_associations

    should "build a list of association objects " \
           "for every ActiveRecord belongs to association" do
      associations = subject.associations
      assert_equal 1, associations.size

      association = associations.first
      assert_instance_of MR::Factory::Record::Association, association
      assert_equal AreaRecord, association.record_class
      assert_equal :area,      association.name
    end

    should "set the record's association given another Record with #set_association" do
      stack_record = MR::Factory::Record.new(AreaRecord.new)
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

  class StackRecordWithAFakeRecordTests < StackRecordTests
    desc "with a fake record"
    setup do
      @fake_user_record = FakeUserRecord.new
      @stack_record = MR::Factory::Record.new(@fake_user_record)
    end

    should "reset the fake record's `save_called` flag using `create`" do
      @stack_record.create
      assert_false @fake_user_record.new_record?
      assert_false @fake_user_record.save_called
    end

  end

end
