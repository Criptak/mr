require 'mr/fake_record'
require 'mr/model'

module MR; end
module MR::TestHelpers
  module_function

  def assert_association_saved(model, association, *args)
    with_backtrace(caller) do
      AssociationSavedAssertion.new(model, association, *args).run(self)
    end
  end

  def assert_not_association_saved(model, association, *args)
    with_backtrace(caller) do
      AssociationNotSavedAssertion.new(model, association, *args).run(self)
    end
  end

  def assert_destroyed(model)
    with_backtrace(caller) do
      ModelDestroyedAssertion.new(model).run(self)
    end
  end

  def assert_not_destroyed(model)
    with_backtrace(caller) do
      ModelNotDestroyedAssertion.new(model).run(self)
    end
  end

  def assert_field_saved(model, field, *args)
    with_backtrace(caller) do
      FieldSavedAssertion.new(model, field, *args).run(self)
    end
  end

  def assert_not_field_saved(model, field, *args)
    with_backtrace(caller) do
      FieldNotSavedAssertion.new(model, field, *args).run(self)
    end
  end

  class AssociationSavedAssertionBase
    def initialize(model, association, *args)
      fake_record = model.instance_eval{ record }
      reflection = fake_record.association(association).reflection
      if reflection.macro != :belongs_to
        raise ArgumentError, "association must be a belongs to"
      end
      @expected_value = args[0] || NULL_MODEL
      @check_value = !args.empty?
      expected_foreign_type = @expected_value.record_class.name
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
      args = [ model, field ]
      (args << expected_value) if @check_value
      self.field_assertion_class.new(*args)
    end

    NullModel = Struct.new(:id, :record_class)
    NullRecordClass = Struct.new(:name)
    NULL_MODEL = NullModel.new(nil, NullRecordClass.new)
  end

  class AssociationSavedAssertion < AssociationSavedAssertionBase
    def field_assertion_class; FieldSavedAssertion; end
  end

  class AssociationNotSavedAssertion < AssociationSavedAssertionBase
    def field_assertion_class; FieldNotSavedAssertion; end
  end

  class FieldSavedAssertionBase
    def initialize(model, field, *args)
      fake_record = model.instance_eval{ record }
      if !fake_record.kind_of?(MR::FakeRecord)
        raise ArgumentError, "model must be using a fake record"
      end
      @field = field.to_s
      previous_attributes = fake_record.previous_attributes
      saved_attributes    = fake_record.saved_attributes

      @expected_value, @check_value = args[0], !args.empty?
      @saved_as = saved_attributes[@field]
      @saved    = saved_attributes.key?(@field)
      @changed  = @saved && previous_attributes[@field] != @saved_as
    end
  end

  class FieldSavedAssertion < FieldSavedAssertionBase
    def run(context)
      context.assert(@changed){ changed_desc }
      return unless @check_value
      context.assert_equal @expected_value, @saved_as, saved_as_desc
    end

    private

    def changed_desc
      "Expected #{@field.inspect} field was saved."
    end

    def saved_as_desc
      "Expected #{@field.inspect} field was saved as #{@expected_value.inspect}."
    end
  end

  class FieldNotSavedAssertion < FieldSavedAssertionBase
    def run(context)
      context.assert(!@changed){ changed_desc }
      return unless @check_value
      context.assert_not_equal @expected_value, @saved_as, saved_as_desc
    end

    private

    def changed_desc
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
      context.assert(@destroyed){ destroyed_desc }
    end

    private

    def destroyed_desc
      "Expected #{@model.inspect} was destroyed."
    end
  end

  class ModelNotDestroyedAssertion < ModelDestroyedAssertionBase
    def run(context)
      context.assert_not(@destroyed){ destroyed_desc }
    end

    private

    def destroyed_desc
      "Expected #{@model.inspect} was not destroyed."
    end
  end

end
