require 'assert'
require 'mr/associations/one_to_one'

require 'test/support/associations'
require 'test/support/models/test_model'

class MR::Associations::OneToOne

  class BaseTests < Assert::Context
    include MR::Associations::TestHelpers

    desc "MR::Associations::OneToOne"
    setup do
      @one_to_one = MR::Associations::OneToOne.new(:test_model, {
        :class_name         => 'TestModel',
        :record_association => 'test_model_belongs_to'
      })
    end
    subject{ @one_to_one }

    should "be a kind of base association" do
      assert_kind_of MR::Associations::Base, subject
    end

    should "return true with one_to_one?" do
      assert_equal true, subject.one_to_one?
    end

    should "read the value of the association reader and " \
           "build an instance of the associated class with #read" do
      test_record = @fake_model_class.new.record
      result = subject.read{ test_record }

      assert_instance_of TestModel, result
      assert_equal test_record.test_model_belongs_to, result.send(:record)
    end

    should "return nil if the association reader returns nil with #read" do
      test_record = @fake_model_class.new.record.tap do |r|
        r.test_model_belongs_to = nil
      end
      result = subject.read{ test_record }

      assert_nil result
    end

    should "raise an error if it isn't passed an MR::Model with #write" do
      test_record = @fake_model_class.new.record

      assert_raises(ArgumentError) do
        subject.write('test'){ test_record }
      end
    end

    should "set the record's association with #write" do
      test_record = @fake_model_class.new.record
      test_model = TestModel.new
      subject.write(test_model){ test_record }

      expected_record = test_model.send(:record)
      assert_equal expected_record, test_record.test_model_belongs_to

      subject.write(nil){ test_record }
      assert_nil test_record.test_model_belongs_to
    end

    should "allow reading and writing using the association" do
      subject.define_methods(@fake_model_class)
      instance = @fake_model_class.new

      expected_model = TestModel.new(instance.record.test_model_belongs_to)
      assert_instance_of TestModel, instance.test_model
      assert_equal expected_model, instance.test_model

      new_model = TestModel.new
      instance.test_model = new_model
      assert_equal new_model, instance.test_model
    end

  end

  class BelongsToTests < Assert::Context
    desc "BelongsTo"
    setup do
      @belongs_to = MR::Associations::BelongsTo.new(:test_model, 'TestModel')
    end
    subject{ @belongs_to }

    should "be a kind of OneToOne" do
      assert_kind_of MR::Associations::OneToOne, subject
    end

  end

  class HasOneTests < Assert::Context
    desc "HasOne"
    setup do
      @has_one = MR::Associations::HasOne.new(:test_model, 'TestModel')
    end
    subject{ @has_one }

    should "be a kind of OneToOne" do
      assert_kind_of MR::Associations::OneToOne, subject
    end

  end

end
