require 'assert'
require 'mr/test_helpers'

require 'mr/factory'
require 'mr/model'

module MR::TestHelpers

  class UnitTests < Assert::Context
    desc "MR::TestHelpers"
    subject{ MR::TestHelpers }

    should have_imeths :model_reset_save_called
    should have_imeths :assert_association_saved, :assert_not_association_saved
    should have_imeths :assert_model_destroyed, :assert_not_model_destroyed
    should have_imeths :assert_model_saved, :assert_not_model_saved
    should have_imeths :assert_field_saved, :assert_not_field_saved

  end

  class WithModelTests < UnitTests
    setup do
      @associated_record = FakeTestRecord.new
      @associated_model = FakeTestModel.new(@associated_record).tap(&:save)
      @model = FakeTestModel.new({
        :name   => 'Test',
        :area   => @associated_model,
        :parent => @associated_model
      })
    end
  end

  class TestingActualModelTests < WithModelTests
    include MR::TestHelpers

    desc "with an actual model"
    subject{ @model }

    should "be able to test if an association was saved or not" do
      assert_not_model_saved subject
      assert_not_association_saved subject, :parent, @associated_model
      @model.save
      assert_model_saved subject
      assert_association_saved subject, :parent, @associated_model
      @other_model = FakeTestModel.new.tap(&:save)
      @model.parent = @other_model
      @model.save
      assert_association_saved subject, :parent, @other_model
    end

    should "be able to test if an polymorphic association was saved when " \
           "the model `record_class` doesn't match it's actual record's class" do
      associated_record = OtherFakeTestRecord.new
      associated_model  = FakeTestModel.new(associated_record).tap(&:save)
      @model.parent = associated_model
      @model.save
      assert_model_saved subject
      assert_association_saved subject, :parent, associated_model
    end

    should "be able to test if a field was saved or not" do
      assert_not_model_saved subject
      assert_not_field_saved subject, :name, 'Test'
      @model.save
      assert_model_saved subject
      assert_field_saved subject, :name, 'Test'
      @model.name = 'Joe'
      @model.save
      assert_field_saved subject, :name, 'Joe'
    end

    should "be able to test if a model was destroyed or not" do
      assert_not_model_destroyed subject
      @model.save
      assert_not_model_destroyed subject
      @model.destroy
      assert_model_destroyed subject
    end

    should "reset a fake model's `save_called` state using `model_reset_save_called`" do
      @model.save
      model_reset_save_called @model
      assert_not_model_saved @model
    end

    should "yield the model passed to it before resetting using `model_reset_save_called`" do
      yielded = nil
      model_reset_save_called(@model) do |m|
        yielded = m
        m.save
      end
      assert_equal @model, yielded
      assert_not_model_saved @model
    end

    should "raise an ArgumentError when passed a model not using a fake record" do
      record_class = Class.new{ include MR::Record }
      model = FakeTestModel.new(record_class.new)
      assert_raises(ArgumentError){ model_reset_save_called(model) }
    end

  end

  class WithAssertContextSpyTests < WithModelTests
    setup do
      @model.save
      @assert_context_spy = AssertContextSpy.new
    end
  end

  class AssociationSavedAssertionBaseTests < WithAssertContextSpyTests
    desc "AssociationSavedAssertionBase"

    should "raise an ArgumentError when given a non belongs to association" do
      assert_raises(ArgumentError) do
        AssociationSavedAssertionBase.new(@model, :comments)
      end
    end

  end

  class AssociationSavedAssertionTests < WithAssertContextSpyTests
    desc "AssociationSavedAssertion"
    setup do
      @assertion = AssociationSavedAssertion.new(
        @model,
        :area,
        @associated_model
      )
    end
    subject{ @assertion }

    should have_imeths :run

    should "assert that the association's foreign key was saved as " \
           "the expected value when run" do
      subject.run(@assert_context_spy)
      assert_equal 1, @assert_context_spy.results.size
      assert_equal [ true ], @assert_context_spy.results.map(&:value)
      descriptions = @assert_context_spy.results.map(&:desc)
      expected = "Expected \"area_id\" field was saved " \
                 "as #{@associated_model.id}."
      assert_includes expected, descriptions
    end

  end

  class AssociationSavedAssertionPolyTests < AssociationSavedAssertionTests
    desc "run for a polymorphic belongs to"
    setup do
      @assertion = AssociationSavedAssertion.new(
        @model,
        :parent,
        @associated_model
      )
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have asserted that the association's foreign type and key " \
           "were saved as the expected value" do
      assert_equal 2, subject.size
      assert_equal [ true, true ], subject.map(&:value)
      descriptions = @assert_context_spy.results.map(&:desc)
      expected = "Expected \"parent_type\" field was saved " \
                 "as #{@associated_record.class.name.inspect}."
      assert_includes expected, descriptions
      expected = "Expected \"parent_id\" field was saved " \
                 "as #{@associated_model.id}."
      assert_includes expected, descriptions
    end

  end

  class AssociationNotSavedAssertionTests < WithAssertContextSpyTests
    desc "AssociationNotSavedAssertion"
    setup do
      @assertion = AssociationNotSavedAssertion.new(
        @model,
        :area,
        @associated_model
      )
    end
    subject{ @assertion }

    should have_imeths :run

    should "assert that the association's foreign key was not saved " \
           "as the expected value when run" do
      subject.run(@assert_context_spy)
      assert_equal 1, @assert_context_spy.results.size
      assert_equal [ false ], @assert_context_spy.results.map(&:value)
      descriptions = @assert_context_spy.results.map(&:desc)
      expected = "Expected \"area_id\" field was not saved " \
                 "as #{@associated_model.id}."
      assert_includes expected, descriptions
    end

  end

  class AssociationNotSavedAssertionPolyTests < AssociationNotSavedAssertionTests
    desc "is run for a polymorphic belongs to"
    setup do
      @assertion = AssociationNotSavedAssertion.new(
        @model,
        :parent,
        @associated_model
      )
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have asserted that the association's foreign type was not saved " \
           "as the expected value" do
      assert_equal 2, subject.size
      assert_equal [ false, false ], subject.map(&:value)
      descriptions = @assert_context_spy.results.map(&:desc)
      expected = "Expected \"parent_type\" field was not saved " \
                 "as #{@associated_record.class.name.inspect}."
      assert_includes expected, descriptions
      expected = "Expected \"parent_id\" field was not saved " \
                 "as #{@associated_model.id}."
      assert_includes expected, descriptions
    end

  end

  class FieldSavedAssertionBaseTests < WithAssertContextSpyTests
    desc "FieldSavedAssertionBase"
    setup do
      @assertion = FieldSavedAssertionBase.new(@model, :name, 'Test')
    end
    subject{ @assertion }

    should "raise an ArgumentError with a model not using a fake record" do
      record_class = Class.new{ include MR::Record }
      model = FakeTestModel.new(record_class.new)
      assert_raises(ArgumentError){ FieldSavedAssertionBase.new(model, :name) }
    end

  end

  class FieldSavedAssertionTests < WithAssertContextSpyTests
    desc "FieldSavedAssertion"
    setup do
      @assertion = FieldSavedAssertion.new(@model, :name, 'Test')
    end
    subject{ @assertion }

    should have_imeths :run

  end

  class FieldSavedAssertionSavedTests < FieldSavedAssertionTests
    desc "when run for a field on a saved model"
    setup do
      @assertion = FieldSavedAssertion.new(@model, :name, 'Test')
      @assertion.run(@assert_context_spy)
      @results = @assert_context_spy.results
    end

    should "assert that the field was saved as the expected value when run" do
      assert_equal 1, @results.size
      assert_equal [ true ], @results.map(&:value)
      expected = "Expected \"name\" field was saved as \"Test\"."
      assert_includes expected, @results.map(&:desc)
    end

  end

  class FieldSavedAssertionUnsavedTests < FieldSavedAssertionTests
    desc "when run for a field on an unsaved model"
    setup do
      # this ensures that this test doesn't pass, a `nil` expected value would
      # pass if the assertion class only used `assert_equal`
      @assertion = FieldSavedAssertion.new(FakeTestModel.new, :name, nil)
      @assertion.run(@assert_context_spy)
      @results = @assert_context_spy.results
    end

    should "assert that the field was saved when run" do
      assert_equal 1, @results.size
      assert_equal [ false ], @results.map(&:value)
      expected = "Expected \"name\" field was saved."
      assert_includes expected, @results.map(&:desc)
    end

  end

  class FieldNotSavedAssertionTests < WithAssertContextSpyTests
    desc "FieldNotSavedAssertion"
    setup do
      @assertion = FieldNotSavedAssertion.new(@model, :other, 'Test')
    end
    subject{ @assertion }

    should have_imeths :run

  end

  class FieldNotSavedAssertionSavedTests < FieldNotSavedAssertionTests
    desc "when run for a field on a saved model"
    setup do
      @assertion = FieldNotSavedAssertion.new(@model, :name, 'Test')
      @assertion.run(@assert_context_spy)
      @results = @assert_context_spy.results
    end

    should "assert that the field was not saved as the expected value when run" do
      assert_equal 1, @results.size
      assert_equal [ false ], @results.map(&:value)
      expected = "Expected \"name\" field was not saved as \"Test\"."
      assert_includes expected, @results.map(&:desc)
    end

  end

  class FieldNotSavedAssertionUnsavedTests < FieldNotSavedAssertionTests
    desc "when run for a field on an unsaved model"
    setup do
      # this ensures that this test does pass, a non `nil` expected value would
      # fail if the assertion class only used `assert_not_equal`
      @assertion = FieldNotSavedAssertion.new(FakeTestModel.new, :name, 'Test')
      @assertion.run(@assert_context_spy)
      @results = @assert_context_spy.results
    end

    should "assert that the field was not saved when run" do
      assert_equal 1, @results.size
      assert_equal [ true ], @results.map(&:value)
      expected = "Expected \"name\" field was not saved."
      assert_includes expected, @results.map(&:desc)
    end

  end

  class ModelDestroyedAssertionTests < WithAssertContextSpyTests
    desc "ModelDestroyedAssertion"
    setup do
      @model.destroy
      @assertion = ModelDestroyedAssertion.new(@model)
    end
    subject{ @assertion }

    should have_imeths :run

    should "assert that the model was destroyed using `run`" do
      @assertion.run(@assert_context_spy)
      result = @assert_context_spy.results.last
      assert_true result.value
      assert_equal "Expected #{@model.inspect} was destroyed.", result.block.call
    end

  end

  class ModelNotDestroyedAssertionTests < WithAssertContextSpyTests
    desc "ModelNotDestroyedAssertion"
    setup do
      @assertion = ModelNotDestroyedAssertion.new(@model)
    end
    subject{ @assertion }

    should have_imeths :run

    should "assert that the model was not destroyed using `run`" do
      @assertion.run(@assert_context_spy)
      result = @assert_context_spy.results.last
      assert_true result.value
      assert_equal "Expected #{@model.inspect} was not destroyed.", result.block.call
    end

  end

  class AssertContextSpy
    attr_reader :results

    def initialize
      @results = []
    end

    def assert_true(actual, desc = nil, &block)
      self.assert_equal(true, actual, desc, &block)
    end

    def assert_false(actual, desc = nil, &block)
      self.assert_equal(false, actual, desc, &block)
    end

    def assert_equal(expected, actual, desc = nil, &block)
      self.assert(expected == actual, desc, &block)
    end

    def assert_not_equal(expected, actual, desc = nil, &block)
      self.assert(expected != actual, desc)
    end

    def assert(value, desc = nil, &block)
      @results << Result.new(value, desc, block)
    end

    class Result < Struct.new(:value, :desc, :block)
      def what_failed; (block || proc{ }).call; end
    end
  end

  class FakeTestRecord
    include MR::FakeRecord
    attribute :name,        :string
    attribute :active,      :boolean
    attribute :area_id,     :integer
    attribute :parent_type, :string
    attribute :parent_id,   :integer
    polymorphic_belongs_to :parent
    belongs_to :area, self.to_s
    has_many :comments, self.to_s
  end

  class OtherFakeTestRecord
    include MR::FakeRecord
  end

  class FakeTestModel
    include MR::Model
    record_class FakeTestRecord
    field_accessor :id, :name, :active, :parent_id, :parent_type
    polymorphic_belongs_to :parent
    belongs_to :area
    has_many :comments
  end

end
