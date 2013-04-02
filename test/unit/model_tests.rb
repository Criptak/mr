require 'assert'
require 'mr/model'
require 'ns-options/assert_macros'
require 'test/support/test_models'

module MR::Model

  class BaseTests < Assert::Context
    desc "MR::Model"
    setup do
      @fake_test_record = TestFakeRecord.new({ :id => 1 })
      @test_model = TestModel.new(@fake_test_record)
    end
    subject{ @test_model }

    should have_accessors :fields
    should have_instance_methods :save, :destroy, :transaction, :valid?
    should have_class_methods :mr_config, :record_class, :fields, :field_reader,
      :field_writer, :field_accessor

    should "allow an optional record and fields to it's initialize" do
      fake_test_record = TestFakeRecord.new
      passed_fields = { :name => 'Test' }
      empty_fields = { :id => nil, :name => nil }
      set_fields = { :id => nil, :name => 'Test' }

      # pass nothing
      test_model = TestModel.new

      assert_instance_of TestFakeRecord, test_model.send(:record)
      assert_equal empty_fields, test_model.fields

      # pass just a record
      test_model = TestModel.new(fake_test_record)

      assert_equal fake_test_record, test_model.send(:record)
      assert_equal empty_fields,     test_model.fields

      # pass just fields
      test_model = TestModel.new(passed_fields)

      assert_instance_of TestFakeRecord, test_model.send(:record)
      assert_equal set_fields, test_model.fields

      # pass both a record and fields
      test_model = TestModel.new(fake_test_record, passed_fields)

      assert_equal fake_test_record, test_model.send(:record)
      assert_equal set_fields,       test_model.fields
    end

    should "be comparable" do
      matching_model = TestModel.new(@fake_test_record)
      non_matching_model = TestModel.new(TestFakeRecord.new)

      assert_equal     matching_model,     subject
      assert_not_equal non_matching_model, subject
    end

  end

  class ConfigTests < BaseTests
    include NsOptions::AssertMacros

    desc "mr_config"
    setup do
      @config = TestModel.mr_config
    end
    subject{ @config }

    should have_options :record_class
    should have_option :fields, Set, :default => []

    should "return the configured record class" do
      assert_equal TestFakeRecord, subject.record_class
    end

    should "return the configured fields" do
      expected = Set.new([ :id, :name ])
      assert_equal expected, subject.fields
    end

  end

  class FieldsAccessorTests < BaseTests
    desc "fields reading and writing"

    should "return any keys in the fields configuration with #fields" do
      fields = subject.fields

      assert fields.key?(:id)
      assert fields.key?(:name)
    end

    should "allow calling any writer method with #fields=" do
      assert_not subject.class.fields.include? :special

      assert_nothing_raised do
        subject.fields = { :special => 'test' }
      end

      assert_equal 'test', subject.special
    end

    should "throw a NoMethodError when #fields= is given keys " \
           "for fields without a writer method" do
      assert_raises(NoMethodError) do
        subject.fields = { :id => 1 }
      end
    end

    should "throw a NoMethodError when #fields= is given keys " \
           "that don't have writer methods defined" do
      assert_raises(NoMethodError) do
        subject.fields = { :not_a_valid_writer => true }
      end
    end

  end

  class PersistenceMethodsTests < BaseTests
    desc "persistence methods"

    should "call the save! method on it's record with #save" do
      assert_nil @fake_test_record.saved_attributes

      subject.save

      assert_not_nil @fake_test_record.saved_attributes
    end

    should "allow setting fields when saved" do
      subject.save({ :name => 'Test' })
      saved = @fake_test_record.saved_attributes

      assert_equal 'Test', saved[:name]
    end

    should "call the destroy method on it's record with #destroy" do
      assert_equal false, @fake_test_record.destroyed?

      subject.destroy

      assert_equal true, @fake_test_record.destroyed?
    end

    should "call the record's transaction with #transaction" do
      value = nil
      # a fake record's transaction just yields
      subject.transaction{ value = true }

      assert_equal true, value
    end

    should "call the record's valid? with #valid?" do
      assert_equal @fake_test_record.valid?, subject.valid?
    end

  end

  class CallbacksTests < BaseTests
    desc "callbacks"

    should "call the save and create ones when the record is a new record" do
      @fake_test_record.stubs(:new_record?).returns(true)
      subject.save

      assert_equal true, subject.before_save_called
      assert_equal true, subject.before_create_called
      assert_equal nil,  subject.before_update_called
      assert_equal nil,  subject.after_update_called
      assert_equal true, subject.after_create_called
      assert_equal true, subject.after_save_called
    end

    should "call save and update ones when the record isn't a new record" do
      @fake_test_record.stubs(:new_record?).returns(false)
      subject.save

      assert_equal true, subject.before_save_called
      assert_equal nil,  subject.before_create_called
      assert_equal true, subject.before_update_called
      assert_equal true, subject.after_update_called
      assert_equal nil,  subject.after_create_called
      assert_equal true, subject.after_save_called
    end

    should "call the destroy ones when the record is destroyed" do
      subject.destroy

      assert_equal true, subject.before_destroy_called
      assert_equal true, subject.after_destroy_called
    end

  end

end
