require 'assert'
require 'mr/test_helpers'
require 'test/support/ar_models'

module MR::TestHelpers

  class FakeContext
    include MR::TestHelpers
    attr_reader :assertions
    def initialize
      @assertions = []
    end
    def run(*args, &block)
      self.instance_exec(*args, &block)
    end
    def assert(assertion, *args)
      @assertions << assertion
    end
  end

  class BaseTests < Assert::Context
    desc "MR::TestHelpers"
    setup do
      @record  = FakeUserRecord.new
      @model   = User.new(@record)
      @context = FakeContext.new
    end
    subject{ @context }

    should "check if the model was destroyed with assert_destroyed and " \
           "assert_not_destroyed" do
      @context.run(@model){|model| assert_destroyed model }
      assert_equal false, @context.assertions.last

      @context.run(@model){|model| assert_not_destroyed model }
      assert_equal true,  @context.assertions.last

      @model.destroy

      @context.run(@model){|model| assert_destroyed model }
      assert_equal true, @context.assertions.last

      @context.run(@model){|model| assert_not_destroyed model }
      assert_equal false,  @context.assertions.last
    end

    should "check if a model's field was saved with assert_field_saved and " \
           "assert_field_not_saved" do
      @context.run(@model){|model| assert_field_saved model, :name }
      assert_equal false, @context.assertions.last

      @context.run(@model){|model| assert_field_saved model, :name, 'Test' }
      assert_equal false, @context.assertions.last

      @context.run(@model){|model| assert_not_field_saved model, :name }
      assert_equal true, @context.assertions.last

      @context.run(@model){|model| assert_not_field_saved model, :name, 'Test' }
      assert_equal true, @context.assertions.last

      @model.save({ :name => 'Joe' })

      @context.run(@model){|model| assert_field_saved model, :name }
      assert_equal true, @context.assertions.last

      @context.run(@model){|model| assert_field_saved model, :name, 'Joe' }
      assert_equal true, @context.assertions.last

      @context.run(@model){|model| assert_field_saved model, :name, 'Test' }
      assert_equal false, @context.assertions.last

      @context.run(@model){|model| assert_not_field_saved model, :name }
      assert_equal false, @context.assertions.last

      @context.run(@model){|model| assert_not_field_saved model, :name, 'Joe' }
      assert_equal false, @context.assertions.last

      @context.run(@model){|model| assert_not_field_saved model, :name, 'Test' }
      assert_equal true, @context.assertions.last
    end

  end

end
