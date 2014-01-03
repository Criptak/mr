require 'mr/fake_record'

module MR; end
module MR::TestHelpers
  module_function

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
