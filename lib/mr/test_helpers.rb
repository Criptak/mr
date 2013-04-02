module MR; end
module MR::TestHelpers

  # `module_function` makes every method a private instance method and a
  # public class method. Thus, the module can either be used directly or
  # included on a class.

  module_function

  # Need to detect if a third arg is passed at all. If it's passed, then the
  # intent is to check if the field was saved as the value (the final arg). If
  # a third arg isn't passed, the intent is to only check that it was saved.

  def assert_field_saved(model, field_name, *args)
    value, check_value = args[0], !args.empty?

    if !model || !field_name
      raise ArgumentError, "a model and field name must be provided"
    end

    saved = model.send(:record).saved_attributes
    if check_value
      desc = "Expected #{field_name.inspect} was saved as #{value.inspect}"
      assert_equal args[0], saved[field_name.to_sym], desc
    else
      desc = "Expected #{field_name.inspect} was saved"
      assert saved.key?(field_name.to_sym), desc
    end
  end

  def assert_not_field_saved(model, field_name, *args)
    value, check_value = args[0], !args.empty?

    if !model || !field_name
      raise ArgumentError, "a model and field name must be provided"
    end

    saved = model.send(:record).saved_attributes
    if check_value
      desc = "Expected #{field_name.inspect} was not saved as #{value.inspect}"
      assert_not_equal value, saved[field_name.to_sym], desc
    else
      desc = "Expected #{field_name.inspect} was not saved"
      assert_not saved.key?(field_name.to_sym), desc
    end
  end

  def assert_destroyed(model)
    assert model.send(:record).destroyed?
  end

  def assert_not_destroyed(model)
    assert_not model.send(:record).destroyed?
  end

end
