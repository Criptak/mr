require 'assert'
require 'mr/test_helpers'

require 'mr/factory'
require 'mr/model'

module MR::TestHelpers

  class UnitTests < Assert::Context
    desc "MR::TestHelpers"
    subject{ MR::TestHelpers }

    should have_imeths :assert_association_saved, :assert_not_association_saved
    should have_imeths :assert_destroyed, :assert_not_destroyed
    should have_imeths :assert_field_saved, :assert_not_field_saved

  end

  class WithModelTests < UnitTests
    setup do
      @associated_model = FakeTestModel.new.tap(&:save)
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
      assert_not_association_saved subject, :parent
      assert_not_association_saved subject, :parent, @associated_model
      @model.save
      assert_association_saved subject, :parent
      assert_association_saved subject, :parent, @associated_model
      @model.save
      assert_not_association_saved subject, :parent
      assert_not_association_saved subject, :parent, @associated_model
      @other_model = FakeTestModel.new.tap(&:save)
      @model.parent = @other_model
      @model.save
      assert_association_saved subject, :parent
      assert_association_saved subject, :parent, @other_model
    end

    should "be able to test if a field was saved or not" do
      assert_not_field_saved subject, :name
      assert_not_field_saved subject, :name, 'Test'
      @model.save
      assert_field_saved subject, :name
      assert_field_saved subject, :name, 'Test'
      @model.save
      assert_not_field_saved subject, :name
      assert_not_field_saved subject, :name, 'Test'
      @model.name = 'Joe'
      @model.save
      assert_field_saved subject, :name
      assert_field_saved subject, :name, 'Joe'
    end

    should "be able to test if a model was destroyed or not" do
      assert_not_destroyed subject
      @model.save
      assert_not_destroyed subject
      @model.destroy
      assert_destroyed subject
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
      @assertion = AssociationSavedAssertion.new(@model, :area)
    end
    subject{ @assertion }

    should have_imeths :run

  end

  class AssociationSavedAssertionNoValueTests < AssociationSavedAssertionTests
    desc "with no expected value is run"
    setup do
      @assertion = AssociationSavedAssertion.new(@model, :area)
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 1 positive assertion result" do
      assert_equal 1, subject.size
      assert_equal [ true ], subject.map(&:value)
    end

    should "have asserted that the association's foreign key was saved" do
      expected = "Expected \"area_id\" field was saved."
      assert_includes expected, subject.map(&:what_failed)
    end

  end

  class AssociationSavedAssertionValueTests < AssociationSavedAssertionTests
    desc "with an expected value is run"
    setup do
      @assertion = AssociationSavedAssertion.new(
        @model,
        :area,
        @associated_model
      )
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 2 positive assertion results" do
      assert_equal 2, subject.size
      assert_equal [ true, true ], subject.map(&:value)
    end

    should "have asserted that the association's foreign key was saved and " \
           "is equal to the expected value" do
      expected = "Expected \"area_id\" field was saved."
      assert_includes expected, subject.map(&:what_failed)
      expected = "Expected \"area_id\" field was saved " \
                 "as #{@associated_model.id}."
      assert_includes expected, subject.map(&:desc)
    end

  end

  class AssociationSavedAssertionPolyNoValueTests < AssociationSavedAssertionTests
    desc "with no expected value is run for a polymorphic belongs to"
    setup do
      @assertion = AssociationSavedAssertion.new(@model, :parent)
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 2 positive assertion result" do
      assert_equal 2, subject.size
      assert_equal [ true, true ], subject.map(&:value)
    end

    should "have asserted that the association's foreign key and type were saved" do
      messages = subject.map(&:what_failed)
      assert_includes "Expected \"parent_type\" field was saved.", messages
      assert_includes "Expected \"parent_id\" field was saved.", messages
    end

  end

  class AssociationSavedAssertionPolyValueTests < AssociationSavedAssertionTests
    desc "with an expected value is run for a polymorphic belongs to"
    setup do
      @assertion = AssociationSavedAssertion.new(
        @model,
        :parent,
        @associated_model
      )
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 4 positive assertion results" do
      assert_equal 4, subject.size
      assert_equal [ true, true, true, true ], subject.map(&:value)
    end

    should "have asserted that the association's foreign typed was saved and " \
           "is equal to the expected value" do
      expected = "Expected \"parent_type\" field was saved."
      assert_includes expected, subject.map(&:what_failed)
      expected = "Expected \"parent_type\" field was saved " \
                 "as #{@associated_model.record_class.name.inspect}."
      assert_includes expected, subject.map(&:desc)
    end

    should "have asserted that the association's foreign key was saved and " \
           "is equal to the expected value" do
      expected = "Expected \"parent_id\" field was saved."
      assert_includes expected, subject.map(&:what_failed)
      expected = "Expected \"parent_id\" field was saved " \
                 "as #{@associated_model.id}."
      assert_includes expected, subject.map(&:desc)
    end

  end

  class AssociationNotSavedAssertionTests < WithAssertContextSpyTests
    desc "AssociationNotSavedAssertion"
    setup do
      @assertion = AssociationNotSavedAssertion.new(@model, :area)
    end
    subject{ @assertion }

    should have_imeths :run

  end

  class AssociationNotSavedAssertionNoValueTests < AssociationNotSavedAssertionTests
    desc "with no expected value is run"
    setup do
      @assertion = AssociationNotSavedAssertion.new(@model, :area)
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 1 negative assertion result" do
      assert_equal 1, subject.size
      assert_equal [ false ], subject.map(&:value)
    end

    should "have asserted that the association's foreign key was not saved" do
      expected = "Expected \"area_id\" field was not saved."
      assert_includes expected, subject.map(&:what_failed)
    end

  end

  class AssociationNotSavedAssertionValueTests < AssociationNotSavedAssertionTests
    desc "with an expected value is run"
    setup do
      @assertion = AssociationNotSavedAssertion.new(
        @model,
        :area,
        @associated_model
      )
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 2 negative assertion results" do
      assert_equal 2, subject.size
      assert_equal [ false, false ], subject.map(&:value)
    end

    should "have asserted that the association's foreign key was not saved " \
           "and is not equal to the expected value" do
      expected = "Expected \"area_id\" field was not saved."
      assert_includes expected, subject.map(&:what_failed)
      expected = "Expected \"area_id\" field was not saved " \
                 "as #{@associated_model.id}."
      assert_includes expected, subject.map(&:desc)
    end

  end

  class AssociationNotSavedAssertionPolyNoValueTests < AssociationNotSavedAssertionTests
    desc "with no expected value is run for a polymorphic belongs to"
    setup do
      @assertion = AssociationNotSavedAssertion.new(@model, :parent)
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 2 negative assertion results" do
      assert_equal 2, subject.size
      assert_equal [ false, false ], subject.map(&:value)
    end

    should "have asserted that the association's foreign key and " \
           "type were not saved" do
      messages = subject.map(&:what_failed)
      assert_includes "Expected \"parent_type\" field was not saved.", messages
      assert_includes "Expected \"parent_id\" field was not saved.", messages
    end

  end

  class AssociationNotSavedAssertionPolyValueTests < AssociationNotSavedAssertionTests
    desc "with an expected value is run for a polymorphic belongs to"
    setup do
      @assertion = AssociationNotSavedAssertion.new(
        @model,
        :parent,
        @associated_model
      )
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 4 negative assertion results" do
      assert_equal 4, subject.size
      assert_equal [ false, false, false, false ], subject.map(&:value)
    end

    should "have asserted that the association's foreign type was not saved " \
           "and is not equal to the expected value" do
      expected = "Expected \"parent_type\" field was not saved."
      assert_includes expected, subject.map(&:what_failed)
      expected = "Expected \"parent_type\" field was not saved " \
                 "as #{@associated_model.record_class.name.inspect}."
      assert_includes expected, subject.map(&:desc)
    end

    should "have asserted that the association's foreign key was not saved " \
           "and is not equal to the expected value" do
      expected = "Expected \"parent_id\" field was not saved."
      assert_includes expected, subject.map(&:what_failed)
      expected = "Expected \"parent_id\" field was not saved " \
                 "as #{@associated_model.id}."
      assert_includes expected, subject.map(&:desc)
    end

  end

  class FieldSavedAssertionBaseTests < WithAssertContextSpyTests
    desc "FieldSavedAssertionBase"
    setup do
      @assertion = FieldSavedAssertionBase.new(@model, :name)
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
      @assertion = FieldSavedAssertion.new(@model, :name)
    end
    subject{ @assertion }

    should have_imeths :run

  end

  class FieldSavedAssertionNoValueTests < FieldSavedAssertionTests
    desc "with no expected value, is run"
    setup do
      @assertion = FieldSavedAssertion.new(@model, :name)
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 1 positive assertion result" do
      assert_equal 1, subject.size
      assert_equal [ true ], subject.map(&:value)
    end

    should "have asserted that the field was saved" do
      expected = "Expected \"name\" field was saved."
      assert_includes expected, subject.map(&:what_failed)
    end

  end

  class FieldSavedAssertionValueTests < FieldSavedAssertionTests
    desc "with an expected value, is run"
    setup do
      @assertion = FieldSavedAssertion.new(@model, :name, 'Test')
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 2 positive assertion results" do
      assert_equal 2, subject.size
      assert_equal [ true, true ], subject.map(&:value)
    end

    should "have asserted that the field was saved and " \
           "is equal to the expected value" do
      expected = "Expected \"name\" field was saved."
      assert_includes expected, subject.map(&:what_failed)
      expected = "Expected \"name\" field was saved as \"Test\"."
      assert_includes expected, subject.map(&:desc)
    end

  end

  class FieldSavedAssertionUnsavedTests < FieldSavedAssertionTests
    desc "for an unsaved field"

    should "add a false result with `run`" do
      FieldSavedAssertion.new(@model, :active).run(@assert_context_spy)
      assert_equal [ false ], @assert_context_spy.results.map(&:value)
    end

    should "add 2 false results with `run` and any expected value" do
      FieldSavedAssertion.new(@model, :active, 'Test').run(@assert_context_spy)
      assert_equal [ false, false ], @assert_context_spy.results.map(&:value)
    end

  end

  class FieldSavedAssertionSavedTests < FieldSavedAssertionTests
    desc "for a saved field"

    should "add a true result with `run`" do
      FieldSavedAssertion.new(@model, :name).run(@assert_context_spy)
      assert_equal [ true ], @assert_context_spy.results.map(&:value)
    end

    should "add 2 true results with `run` and a matching value" do
      FieldSavedAssertion.new(@model, :name, 'Test').run(@assert_context_spy)
      assert_equal [ true, true ], @assert_context_spy.results.map(&:value)
    end

    should "add a true and false result with `run` and a non-matching value" do
      FieldSavedAssertion.new(@model, :name, 'Joe').run(@assert_context_spy)
      assert_equal [ true, false ], @assert_context_spy.results.map(&:value)
    end

  end

  class FieldNotSavedAssertionTests < WithAssertContextSpyTests
    desc "FieldNotSavedAssertion"
    setup do
      @assertion = FieldNotSavedAssertion.new(@model, :name)
    end
    subject{ @assertion }

    should have_imeths :run

  end

  class FieldNotSavedAssertionNoValueTests < FieldSavedAssertionTests
    desc "with no expected value, is run"
    setup do
      @assertion = FieldNotSavedAssertion.new(@model, :name)
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 1 negative assertion result" do
      assert_equal 1, subject.size
      assert_equal [ false ], subject.map(&:value)
    end

    should "have asserted that the field was not saved" do
      expected = "Expected \"name\" field was not saved."
      assert_includes expected, subject.map(&:what_failed)
    end

  end

  class FieldNotSavedAssertionValueTests < FieldSavedAssertionTests
    desc "with an expected value, is run"
    setup do
      @assertion = FieldNotSavedAssertion.new(@model, :name, 'Test')
      @assertion.run(@assert_context_spy)
    end
    subject{ @assert_context_spy.results }

    should "have generated 2 negative assertion results" do
      assert_equal 2, subject.size
      assert_equal [ false, false ], subject.map(&:value)
    end

    should "have asserted that the field was not saved and " \
           "is not equal to the expected value" do
      expected = "Expected \"name\" field was not saved."
      assert_includes expected, subject.map(&:what_failed)
      expected = "Expected \"name\" field was not saved as \"Test\"."
      assert_includes expected, subject.map(&:desc)
    end

  end

  class FieldNotSavedAssertionUnsavedTests < FieldNotSavedAssertionTests
    desc "for an unsaved field"

    should "add a true result with `run`" do
      FieldNotSavedAssertion.new(@model, :active).run(@assert_context_spy)
      assert_equal [ true ], @assert_context_spy.results.map(&:value)
    end

    should "add 2 true results with `run` and any expected value" do
      FieldNotSavedAssertion.new(@model, :active, 'Test').run(@assert_context_spy)
      assert_equal [ true, true ], @assert_context_spy.results.map(&:value)
    end

  end

  class FieldNotSavedAssertionSavedTests < FieldNotSavedAssertionTests
    desc "for a saved field"

    should "add a false result with `run`" do
      FieldNotSavedAssertion.new(@model, :name).run(@assert_context_spy)
      assert_equal [ false ], @assert_context_spy.results.map(&:value)
    end

    should "add 2 false results with `run` and a matching value" do
      FieldNotSavedAssertion.new(@model, :name, 'Test').run(@assert_context_spy)
      assert_equal [ false, false ], @assert_context_spy.results.map(&:value)
    end

    should "add a false and true result with `run` and a non-matching value" do
      FieldNotSavedAssertion.new(@model, :name, 'Joe').run(@assert_context_spy)
      assert_equal [ false, true ], @assert_context_spy.results.map(&:value)
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

    def assert_equal(expected, actual, desc)
      self.assert(expected == actual, desc)
    end

    def assert_not_equal(expected, actual, desc)
      self.assert(expected != actual, desc)
    end

    def assert_not(value, &block)
      self.assert(!value, &block)
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

  class FakeTestModel
    include MR::Model
    record_class FakeTestRecord
    field_accessor :id, :name, :active, :parent_id, :parent_type
    polymorphic_belongs_to :parent
    belongs_to :area
    has_many :comments
  end

end
