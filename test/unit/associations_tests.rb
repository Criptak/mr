require 'assert'
require 'mr/associations'
require 'ostruct'
require 'test/support/test_models'

module MR::Associations

  class BaseTests < Assert::Context
    setup do

      @klass = Class.new do
        attr_reader :record
        def initialize
          @record = OpenStruct.new({
            :test_model_belongs_to => TestFakeRecord.new({ :id => 3 }),
            :test_model_has_many   => [
              TestFakeRecord.new({ :id => 4 })
            ]
          })
        end
      end

    end
  end

  class BelongsToTests < BaseTests
    desc "MR::Associations::BelongsTo"
    setup do
      @belongs_to = BelongsTo.new(:test_model, 'TestModel', {
        :record_association => 'test_model_belongs_to'
      })
    end
    subject{ @belongs_to }

    should have_instance_methods :reader_method_name, :writer_method_name,
      :association_reader_name, :association_writer_name, :read, :write,
      :define_methods

    should "build all the method names it needs" do
      assert_equal "test_model",  subject.reader_method_name
      assert_equal "test_model=", subject.writer_method_name
      assert_equal "test_model_belongs_to",  subject.association_reader_name
      assert_equal "test_model_belongs_to=", subject.association_writer_name
    end

    should "raise an error when read or write is called without a block" do
      assert_raises(ArgumentError){ subject.read }
      assert_raises(ArgumentError){ subject.write }
    end

    should "raise an error if the associated class name " \
           "can't be constantized with #read" do
      assert_raises(MR::Associations::NoAssociatedClassError) do
        BelongsTo.new(:bad, 'NotAClass').read{ TestFakeRecord.new }
      end
    end

    should "read the value of the association reader and " \
           "build an instance of the associated class with #read" do
      test_record = @klass.new.record
      result = subject.read{ test_record }

      assert_instance_of TestModel, result
      assert_equal test_record.test_model_belongs_to, result.send(:record)
    end

    should "return nil if the association reader returns nil with #read" do
      test_record = @klass.new.record.tap do |r|
        r.test_model_belongs_to = nil
      end
      result = subject.read{ test_record }

      assert_nil result
    end

    should "raise an error if it isn't passed an MR::Model with #write" do
      test_record = @klass.new.record

      assert_raises(ArgumentError) do
        subject.write('test'){ test_record }
      end
    end

    should "set the record's association with #write" do
      test_record = @klass.new.record
      test_model = TestModel.new
      subject.write(test_model){ test_record }

      expected_record = test_model.send(:record)
      assert_equal expected_record, test_record.test_model_belongs_to
    end

    should "add a reader and writer with #define_methods" do
      subject.define_methods(@klass)
      instance = @klass.new
      expected_model = TestModel.new(instance.record.test_model_belongs_to)

      assert_instance_of TestModel, instance.test_model
      assert_equal expected_model, instance.test_model

      new_model = TestModel.new
      instance.test_model = TestModel.new

      assert_equal new_model, instance.test_model
    end

  end

  class HasManyTests < BaseTests
    desc "MR::Associations::HasMany"
    setup do
      @belongs_to = HasMany.new(:test_models, 'TestModel', {
        :record_association => 'test_model_has_many'
      })
    end
    subject{ @belongs_to }

    should have_instance_methods :reader_method_name, :association_reader_name,
      :read, :define_method

    should "build all the method names it needs" do
      assert_equal "test_models",  subject.reader_method_name
      assert_equal "test_model_has_many",  subject.association_reader_name
    end

    should "raise an error when read or write is called without a block" do
      assert_raises(ArgumentError){ subject.read }
    end

    should "raise an error if the associated class name " \
           "can't be constantized with #read" do
      assert_raises(MR::Associations::NoAssociatedClassError) do
        HasMany.new(:bad, 'NotAClass').read{ TestFakeRecord.new }
      end
    end

    should "read the value of the association reader and build an instance" \
           "of the associated class for each record with #read" do
      test_record = @klass.new.record
      result = subject.read{ test_record }
      expected_models = test_record.test_model_has_many.map do |r|
        TestModel.new(r)
      end

      assert_instance_of Array, result
      assert_equal expected_models, result
    end

    should "return an empty array if the association reader returns nil or " \
           "an empty array with #read" do
      test_record = @klass.new.record.tap do |r|
        r.test_model_has_many = nil
      end

      result = subject.read{ test_record }
      assert_equal [], result

      test_record.test_model_has_many = []

      result = subject.read{ test_record }
      assert_equal [], result
    end

    should "add a reader with #define_method" do
      subject.define_method(@klass)
      instance = @klass.new
      expected_models = instance.record.test_model_has_many.map do |r|
        TestModel.new(r)
      end

      assert_instance_of Array, instance.test_models
      assert_equal expected_models, instance.test_models
    end

  end

end
