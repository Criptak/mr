require 'assert'
require 'mr/associations/belongs_to'
require 'test/support/associations_context'

class MR::Associations::BelongsTo

  class BaseTests < AssociationsContext
    desc "MR::Associations::BelongsTo"
    setup do
      @belongs_to = MR::Associations::BelongsTo.new(:test_model, 'TestModel', {
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
        MR::Associations::BelongsTo.new(:bad, 'NotAClass').read{ TestFakeRecord.new }
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

      subject.write(nil){ test_record }
      assert_nil test_record.test_model_belongs_to
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

end
