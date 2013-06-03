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

    saved = model.send(:record).saved_attributes || {}
    has_key  = saved.key?(field_name.to_sym)
    saved_as = saved[field_name.to_sym]

    if check_value
      desc = "Expected #{field_name.inspect} was saved as #{value.inspect}"
      assert has_key && value == saved_as, desc
    else
      desc = "Expected #{field_name.inspect} was saved"
      assert has_key && !saved_as.nil?, desc
    end
  end

  def assert_not_field_saved(model, field_name, *args)
    value, check_value = args[0], !args.empty?

    if !model || !field_name
      raise ArgumentError, "a model and field name must be provided"
    end

    saved = model.send(:record).saved_attributes || {}
    has_key  = saved.key?(field_name.to_sym)
    saved_as = saved[field_name.to_sym]

    if check_value
      desc = "Expected #{field_name.inspect} was not saved as #{value.inspect}"
      assert !has_key || value != saved_as, desc
    else
      desc = "Expected #{field_name.inspect} was not saved"
      assert !has_key, desc
    end
  end

  def assert_destroyed(model)
    desc = "Expected the model to be destroyed"
    assert model.send(:record).destroyed?, desc
  end

  def assert_not_destroyed(model)
    desc = "Expected the model to not be destroyed"
    assert !model.send(:record).destroyed?, desc
  end

end
