require 'mr/fake_record'
require 'mr/model'

module MR; end
module MR::TestHelpers
  module_function

  def assert_association_saved(model, association, expected_value)
    with_backtrace(caller) do
      AssociationSavedAssertion.new(model, association, expected_value).run(self)
    end
  end

  def assert_not_association_saved(model, association, expected_value)
    with_backtrace(caller) do
      AssociationNotSavedAssertion.new(model, association, expected_value).run(self)
    end
  end

  def assert_model_destroyed(model)
    with_backtrace(caller) do
      ModelDestroyedAssertion.new(model).run(self)
    end
  end

  def assert_not_model_destroyed(model)
    with_backtrace(caller) do
      ModelNotDestroyedAssertion.new(model).run(self)
    end
  end

  def assert_field_saved(model, field, expected_value)
    with_backtrace(caller) do
      FieldSavedAssertion.new(model, field, expected_value).run(self)
    end
  end

  def assert_not_field_saved(model, field, expected_value)
    with_backtrace(caller) do
      FieldNotSavedAssertion.new(model, field, expected_value).run(self)
    end
  end

  def assert_model_saved(model)
    with_backtrace(caller) do
      ModelSavedAssertion.new(model).run(self)
    end
  end

  def assert_not_model_saved(model)
    with_backtrace(caller) do
      ModelNotSavedAssertion.new(model).run(self)
    end
  end

  class AssociationSavedAssertionBase
    def initialize(model, association, expected_value)
      fake_record = model.instance_eval{ record }
      reflection = fake_record.association(association).reflection
      if reflection.macro != :belongs_to
        raise ArgumentError, "association must be a belongs to"
      end
      @expected_value = expected_value || NULL_MODEL
      expected_foreign_type = @expected_value.send(:record).class.name
      expected_foreign_key  = @expected_value.id
      @assertions = [
        build_assertion(model, reflection.foreign_type, expected_foreign_type),
        build_assertion(model, reflection.foreign_key,  expected_foreign_key)
      ].compact
    end

    def run(context)
      @assertions.each{ |a| a.run(context) }
    end

    private

    def build_assertion(model, field, expected_value)
      return unless field
      self.field_assertion_class.new(model, field, expected_value)
    end

    NullModel = Struct.new(:id, :record)
    NullRecord = Struct.new(:class)
    NullRecordClass = Struct.new(:name)
    NULL_MODEL = NullModel.new(nil, NullRecord.new(NullRecordClass.new))
  end

  class AssociationSavedAssertion < AssociationSavedAssertionBase
    def field_assertion_class; FieldSavedAssertion; end
  end

  class AssociationNotSavedAssertion < AssociationSavedAssertionBase
    def field_assertion_class; FieldNotSavedAssertion; end
  end

  class FieldSavedAssertionBase
    def initialize(model, field, expected_value)
      fake_record = model.instance_eval{ record }
      if !fake_record.kind_of?(MR::FakeRecord)
        raise ArgumentError, "model must be using a fake record"
      end
      @expected_value = expected_value
      @field = field.to_s
      @saved    = fake_record.saved_attributes.key?(@field)
      @saved_as = fake_record.saved_attributes[@field]
    end
  end

  class FieldSavedAssertion < FieldSavedAssertionBase
    def run(context)
      if @saved
        context.assert_equal @expected_value, @saved_as, saved_as_desc
      else
        context.assert_true @saved, saved_desc
      end
    end

    private

    def saved_desc
      "Expected #{@field.inspect} field was saved."
    end

    def saved_as_desc
      "Expected #{@field.inspect} field was saved as #{@expected_value.inspect}."
    end
  end

  class FieldNotSavedAssertion < FieldSavedAssertionBase
    def run(context)
      if @saved
        context.assert_not_equal @expected_value, @saved_as, saved_as_desc
      else
        context.assert_false @saved, saved_desc
      end
    end

    private

    def saved_desc
      "Expected #{@field.inspect} field was not saved."
    end

    def saved_as_desc
      "Expected #{@field.inspect} field was not saved as #{@expected_value.inspect}."
    end
  end

  class ModelDestroyedAssertionBase
    def initialize(model)
      @model = model
      @destroyed = @model.destroyed?
    end
  end

  class ModelDestroyedAssertion < ModelDestroyedAssertionBase
    def run(context)
      context.assert_true(@destroyed){ destroyed_desc }
    end

    private

    def destroyed_desc
      "Expected #{@model.inspect} was destroyed."
    end
  end

  class ModelNotDestroyedAssertion < ModelDestroyedAssertionBase
    def run(context)
      context.assert_false(@destroyed){ destroyed_desc }
    end

    private

    def destroyed_desc
      "Expected #{@model.inspect} was not destroyed."
    end
  end

  class ModelSavedAssertionBase
    def initialize(model)
      @model = model
      fake_record = model.instance_eval{ record }
      if !fake_record.kind_of?(MR::FakeRecord)
        raise ArgumentError, "model must be using a fake record"
      end
      @saved = fake_record.save_called
    end
  end

  class ModelSavedAssertion < ModelSavedAssertionBase
    def run(context)
      context.assert_true(@saved){ saved_desc }
    end

    private

    def saved_desc
      "Expected #{@model.inspect} was saved."
    end
  end

  class ModelNotSavedAssertion < ModelSavedAssertionBase
    def run(context)
      context.assert_false(@saved){ saved_desc }
    end

    private

    def saved_desc
      "Expected #{@model.inspect} was not saved."
    end
  end

end
