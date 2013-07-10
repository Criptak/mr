require 'assert'
require 'mr/associations/base'

require 'test/support/associations'
require 'test/support/models/fake_test_record'
require 'test/support/models/test_model'

class MR::Associations::Base

  class BaseTests < Assert::Context
    include MR::Associations::TestHelpers

    desc "MR::Associations::Base"
    setup do
      @association = MR::Associations::Base.new(:test_model, {
        :class_name         => 'TestModel',
        :record_association => 'test_model_association'
      })
    end
    subject{ @association }

    should have_imeths :reader_method_name, :writer_method_name
    should have_imeths :association_reader_name, :association_writer_name
    should have_imeths :associated_class
    should have_imeths :read, :write
    should have_imeths :define_methods

    should "build all the method names it needs" do
      assert_equal "test_model",  subject.reader_method_name
      assert_equal "test_model=", subject.writer_method_name
      assert_equal "test_model_association",  subject.association_reader_name
      assert_equal "test_model_association=", subject.association_writer_name
    end

    should "raise an error when read or write is called without a block" do
      assert_raises(ArgumentError){ subject.read }
      assert_raises(ArgumentError){ subject.write }
    end

    should "raise NotImplementedError with #read and #write when " \
           "#read! and #write! aren't overwritten" do
      assert_raises(NotImplementedError) do
        subject.read{ 'test' }
      end
      assert_raises(NotImplementedError) do
        subject.write('test'){ 'test' }
      end
    end

    should "return the constantized associated class when provided" do
      assert_equal TestModel, subject.associated_class
      association = MR::Associations::Base.new(:no_class)
      assert_nil association.associated_class
    end

    should "raise an error if a associated class name " \
           "can't be constantized with #associated_class" do
      assert_raises(MR::Associations::NoAssociatedClassError) do
        a = MR::Associations::Base.new(:bad, :class_name => 'NotAClass')
        a.associated_class
      end
    end

    should "add a reader and writer with #define_methods" do
      subject.define_methods(@fake_model_class)
      instance = @fake_model_class.new

      assert instance.respond_to?(:test_model)
      assert instance.respond_to?(:test_model=)
    end

  end

end
