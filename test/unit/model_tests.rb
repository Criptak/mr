require 'assert'
require 'mr/model'
require 'mr/test_helpers'
require 'ns-options/assert_macros'
require 'test/support/test_models'

module MR::Model

  class BaseTests < Assert::Context
    include MR::TestHelpers

    desc "MR::Model"
    setup do
      @fake_test_record = TestFakeRecord.new({ :id => 1 })
      @test_model = TestModel.new(@fake_test_record)
    end
    subject{ @test_model }

    should have_accessors :fields
    should have_cmeths :mr_config, :record_class
    should have_cmeths :fields, :field_reader, :field_writer, :field_accessor
    should have_cmeths :belongs_to, :has_many
    should have_cmeths :find, :all
    should have_imeths :save, :destroy, :transaction
    should have_imeths :errors, :valid?, :new?, :destroyed?

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

    should "have set the record's model with itself" do
      assert_equal subject, subject.send(:record).model
    end

    should "raise an exception when initialized with an object " \
           "that isn't a kind of MR::Record" do
      assert_raises(MR::Model::InvalidRecordError) do
        TestModel.new('string')
      end
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

      assert_field_saved subject, :name, 'Test'
    end

    should "call the destroy method on it's record with #destroy" do
      assert_not_destroyed subject

      subject.destroy

      assert_destroyed subject
    end

    should "call the record's transaction with #transaction" do
      value = nil
      # a fake record's transaction just yields
      subject.transaction{ value = true }

      assert_equal true, value
    end

    should "call the record's `valid?` with #valid?" do
      assert_equal @fake_test_record.valid?, subject.valid?
    end

    should "call the record's `new_record?` with #new?" do
      assert_equal @fake_test_record.new_record?, subject.new?
    end

    should "call the record's `destroyed?` with #destroyed?" do
      assert_equal @fake_test_record.destroyed?, subject.destroyed?
    end

  end

  class CallbacksTests < BaseTests
    desc "callbacks"

    should "call the save, create, and transaction ones when a new record" do
      @fake_test_record.stubs(:new_record?).returns(true)
      subject.save

      assert_equal true, subject.before_transaction_called
      assert_equal true, subject.before_transaction_on_create_called
      assert_equal nil,  subject.before_transaction_on_update_called
      assert_equal nil,  subject.before_transaction_on_destroy_called
      assert_equal true, subject.before_save_called
      assert_equal true, subject.before_create_called
      assert_equal nil,  subject.before_update_called
      assert_equal nil,  subject.before_destroy_called
      assert_equal nil,  subject.after_destroy_called
      assert_equal nil,  subject.after_update_called
      assert_equal true, subject.after_create_called
      assert_equal true, subject.after_save_called
      assert_equal nil,  subject.after_transaction_on_destroy_called
      assert_equal nil,  subject.after_transaction_on_update_called
      assert_equal true, subject.after_transaction_on_create_called
      assert_equal true, subject.after_transaction_called
    end

    should "call save, update, and transaction ones when not a new record" do
      @fake_test_record.stubs(:new_record?).returns(false)
      subject.save

      assert_equal true, subject.before_transaction_called
      assert_equal nil,  subject.before_transaction_on_create_called
      assert_equal true, subject.before_transaction_on_update_called
      assert_equal nil,  subject.before_transaction_on_destroy_called
      assert_equal true, subject.before_save_called
      assert_equal nil,  subject.before_create_called
      assert_equal true, subject.before_update_called
      assert_equal nil,  subject.before_destroy_called
      assert_equal nil,  subject.after_destroy_called
      assert_equal true, subject.after_update_called
      assert_equal nil,  subject.after_create_called
      assert_equal true, subject.after_save_called
      assert_equal nil,  subject.after_transaction_on_destroy_called
      assert_equal true, subject.after_transaction_on_update_called
      assert_equal nil,  subject.after_transaction_on_create_called
      assert_equal true, subject.after_transaction_called
    end

    should "call the destroy and transaction ones when the record is destroyed" do
      subject.destroy

      assert_equal true, subject.before_transaction_called
      assert_equal nil,  subject.before_transaction_on_create_called
      assert_equal nil,  subject.before_transaction_on_update_called
      assert_equal true, subject.before_transaction_on_destroy_called
      assert_equal nil,  subject.before_save_called
      assert_equal nil,  subject.before_create_called
      assert_equal nil,  subject.before_update_called
      assert_equal true, subject.before_destroy_called
      assert_equal true, subject.after_destroy_called
      assert_equal nil,  subject.after_update_called
      assert_equal nil,  subject.after_create_called
      assert_equal nil,  subject.after_save_called
      assert_equal nil,  subject.after_transaction_on_update_called
      assert_equal nil,  subject.after_transaction_on_create_called
      assert_equal true, subject.after_transaction_on_destroy_called
      assert_equal true, subject.after_transaction_called
    end

    should "call the transaction callbacks anytime a transaction is used" do
      value = nil
      subject.transaction{ value = true }

      assert_equal true, subject.before_transaction_called
      assert_equal nil,  subject.before_transaction_on_create_called
      assert_equal nil,  subject.before_transaction_on_update_called
      assert_equal nil,  subject.before_transaction_on_destroy_called
      assert_equal nil,  subject.before_save_called
      assert_equal nil,  subject.before_create_called
      assert_equal nil,  subject.before_update_called
      assert_equal nil,  subject.before_destroy_called
      assert_equal nil,  subject.after_destroy_called
      assert_equal nil,  subject.after_update_called
      assert_equal nil,  subject.after_create_called
      assert_equal nil,  subject.after_save_called
      assert_equal nil,  subject.after_transaction_on_update_called
      assert_equal nil,  subject.after_transaction_on_create_called
      assert_equal nil,  subject.after_transaction_on_destroy_called
      assert_equal true, subject.after_transaction_called
    end

  end

  class FindTests < BaseTests
    desc "find"
    setup do
      TestFakeRecord.stubs(:find).with(1).returns(@fake_test_record)
      @result = TestModel.find(1)
    end
    teardown do
      TestFakeRecord.unstub(:find)
    end

    should "return the matching model using AR's find method" do
      assert_equal TestModel.new(@fake_test_record), @result
    end

  end

  class AllTests < BaseTests
    desc "all"
    setup do
      @records = [
        TestFakeRecord.new({ :id => 2 }),
        TestFakeRecord.new({ :id => 3 })
      ]
      TestFakeRecord.stubs(:all).returns(@records)
      @result = TestModel.all
    end
    teardown do
      TestFakeRecord.unstub(:all)
    end

    should "return the matching model using AR's find method" do
      expected_models = @records.map{|r| TestModel.new(r) }
      assert_equal expected_models, @result
    end

  end


  class InvalidTests < BaseTests
    desc "when saving an invalid record"
    setup do
      errors_mock = mock("ActiveRecord::Errors")
      @fake_test_record.stubs(:valid?).returns(false)
      @fake_test_record.stubs(:errors).returns(errors_mock)
      errors_mock.stubs(:messages).returns({ :name => [ "can't be blank" ]})
    end

    should "raise a InvalidModel exception with the ActiveRecord error messages" do
      exception = nil
      begin
        @test_model.save
      rescue Exception => exception
      end

      assert_instance_of MR::Model::InvalidError, exception
      assert_equal [ "can't be blank" ], exception.errors[:name]
    end

    should "return the ActiveRecord's error messages with errors" do
      @test_model.valid?

      assert_equal [ "can't be blank" ], @test_model.errors[:name]
    end

  end

end
