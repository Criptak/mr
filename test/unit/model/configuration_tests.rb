require 'assert'
require 'mr/model/configuration'

require 'mr/fake_record'

module MR::Model::Configuration

  class UnitTests < Assert::Context
    desc "MR::Model::Configuration"
    setup do
      @model_class = Class.new do
        include MR::Model::Configuration
      end
    end
    subject{ @model_class }

    should have_imeths :record_class

    should "allow reading and writing it's record class with `record_class`" do
      subject.record_class FakeTestRecord
      assert_equal FakeTestRecord, subject.record_class
    end

    should "raise a no record class error if a record class hasn't been set" do
      assert_raises(MR::Model::NoRecordClassError){ subject.record_class }
    end

    should "raise an ArgumentError when a non MR::Record `record_class` is written" do
      assert_raises(ArgumentError){ subject.record_class('fake-class') }
    end

  end

  class InstanceTests < UnitTests

    # These private methods are tested because they are an interace to the other
    # mixins.

    desc "for a model instance"
    setup do
      @model_class.class_eval do
        record_class FakeTestRecord

        def read_record
          record
        end

        def write_record(record)
          set_record(record)
        end
      end
      @record = FakeTestRecord.new
      @model  = @model_class.new
    end
    subject{ @model }

    should have_imeths :record_class

    should "allow reading the model class' record class using `record_class`" do
      assert_equal @model_class.record_class, subject.record_class
    end

    should "allow reading the `record` through the protected method" do
      subject.write_record(@record)
      assert_equal @record, subject.read_record
    end

    should "set the record's model when `set_record` is called" do
      subject.write_record(@record)
      assert_equal @model, @record.model
    end

    should "raise a no record error if a record hasn't been set" do
      assert_raises(MR::Model::NoRecordError){ subject.read_record }
    end

    should "raise an invalid record error when setting record without an MR::Record" do
      assert_raises(MR::Model::InvalidRecordError){ subject.write_record('fake') }
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
  end

end
