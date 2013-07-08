require 'assert'
require 'mr/stack/record'

require 'test/support/models/area_record'
require 'test/support/models/user_record'

class MR::Stack::Record

  class BaseTests < Assert::Context
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

  class AssociationTests < BaseTests
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
