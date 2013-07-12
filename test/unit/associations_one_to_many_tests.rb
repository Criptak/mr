require 'assert'
require 'mr/associations/one_to_many'

require 'test/support/associations'
require 'test/support/models/test_model'

class MR::Associations::OneToMany

  class BaseTests < Assert::Context
    include MR::Associations::TestHelpers

    desc "MR::Associations::HasMany"
    setup do
      @one_to_many = MR::Associations::OneToMany.new(:test_models, {
        :class_name         => 'TestModel',
        :record_association => 'test_model_has_many'
      })
    end
    subject{ @one_to_many }

    should "be a kind of base association" do
      assert_kind_of MR::Associations::Base, subject
    end

    should "return true with one_to_many?" do
      assert_equal true, subject.one_to_many?
    end

    should "read the value of the association reader and build an instance" \
           "of the associated class for each record with #read" do
      test_record = @fake_model_class.new.record
      result = subject.read{ test_record }
      expected_models = test_record.test_model_has_many.map do |r|
        TestModel.new(r)
      end

      assert_instance_of Array, result
      assert_equal expected_models, result
    end

    should "return an empty array if the association reader returns nil or " \
           "an empty array with #read" do
      test_record = @fake_model_class.new.record.tap do |r|
        r.test_model_has_many = nil
      end

      result = subject.read{ test_record }
      assert_equal [], result

      test_record.test_model_has_many = []

      result = subject.read{ test_record }
      assert_equal [], result
    end

    should "raise an error if it isn't passed MR::Models with #write" do
      test_record = @fake_model_class.new.record

      assert_raises(ArgumentError) do
        subject.write('test'){ test_record }
      end
    end

    should "set the record's association with #write" do
      test_record = @fake_model_class.new.record
      test_models = [ TestModel.new ]
      subject.write(test_models){ test_record }

      expected_record = test_models.map{|m| m.send(:record) }
      assert_equal expected_record, test_record.test_model_has_many

      subject.write(nil){ test_record }
      assert_equal [], test_record.test_model_has_many
    end

    should "allow reading and writing using the association" do
      subject.define_methods(@fake_model_class)
      instance = @fake_model_class.new

      expected_models = instance.record.test_model_has_many.map do |r|
        TestModel.new(r)
      end
      assert_instance_of Array, instance.test_models
      assert_equal expected_models, instance.test_models

      new_model = TestModel.new
      instance.test_models = [ new_model ]
      assert_equal [ new_model ], instance.test_models
    end

  end

  class HasManyTests < Assert::Context
    desc "HasMany"
    setup do
      @has_many = MR::Associations::HasMany.new(:test_models, 'TestModel')
    end
    subject{ @has_many }

    should "be a kind of OneToMany" do
      assert_kind_of MR::Associations::OneToMany, subject
    end

  end

end
