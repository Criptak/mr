require 'assert'
require 'mr/associations/has_many'
require 'test/support/associations_context'

class MR::Associations::HasMany

  class BaseTests < AssociationsContext
    desc "MR::Associations::HasMany"
    setup do
      @belongs_to = MR::Associations::HasMany.new(:test_models, 'TestModel', {
        :record_association => 'test_model_has_many'
      })
    end
    subject{ @belongs_to }

    should have_imeths :reader_method_name, :writer_method_name
    should have_imeths :association_reader_name, :association_writer_name
    should have_imeths :read, :write, :define_methods

    should "build all the method names it needs" do
      assert_equal "test_models",  subject.reader_method_name
      assert_equal "test_models=", subject.writer_method_name
      assert_equal "test_model_has_many",  subject.association_reader_name
      assert_equal "test_model_has_many=", subject.association_writer_name
    end

    should "raise an error when read or write is called without a block" do
      assert_raises(ArgumentError){ subject.read }
      assert_raises(ArgumentError){ subject.write }
    end

    should "raise an error if the associated class name " \
           "can't be constantized with #read" do
      assert_raises(MR::Associations::NoAssociatedClassError) do
        MR::Associations::HasMany.new(:bad, 'NotAClass').read{ TestFakeRecord.new }
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

    should "raise an error if it isn't passed MR::Models with #write" do
      test_record = @klass.new.record

      assert_raises(ArgumentError) do
        subject.write('test'){ test_record }
      end
    end

    should "set the record's association with #write" do
      test_record = @klass.new.record
      test_models = [ TestModel.new ]
      subject.write(test_models){ test_record }

      expected_record = test_models.map{|m| m.send(:record) }
      assert_equal expected_record, test_record.test_model_has_many
    end

    should "add a reader and writer with #define_methods" do
      subject.define_methods(@klass)
      instance = @klass.new
      expected_models = instance.record.test_model_has_many.map do |r|
        TestModel.new(r)
      end

      assert_instance_of Array, instance.test_models
      assert_equal expected_models, instance.test_models

      new_model = TestModel.new
      instance.test_models = [ TestModel.new ]

      assert_equal [ new_model ], instance.test_models
    end

  end

end
