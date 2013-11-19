require 'assert'
require 'mr/test_helpers'

module MR::TestHelpers

  class FakeContext
    include MR::TestHelpers
    attr_reader :assertions, :default_backtrace
    def initialize
      @assertions = []
      @default_backtrace = 'with_backtrace not used'
      @current_backtrace = @default_backtrace
    end
    def run(*args, &block)
      self.instance_exec(*args, &block)
    end
    def assert(result, *args)
      @assertions << Assertion.new(result, @current_backtrace)
    end
    def with_backtrace(bt, &block)
      @current_backtrace = bt
      block.call
      @current_backtrace = @default_backtrace
    end
    Assertion = Struct.new(:result, :backtrace)
  end

  class UnitTests < Assert::Context
    desc "MR::TestHelpers"
    setup do
      @record  = FakeTestRecord.new
      @model   = FakeTestModel.new(@record)
      @context = FakeContext.new
    end
    subject{ @context }

    def last_assertion
      @context.assertions.last
    end

    def assert_result_is(*args, &block)
      exp_result = args.shift
      @context.run(*args, &block)
      with_backtrace(caller) do
        desc = "Expected the assertion to be `#{exp_result}`, not `#{last_assertion.result}"
        assert_equal exp_result, last_assertion.result, desc
        desc = "Expected the helper to use `with_backtrace`"
        assert_not_equal @context.default_backtrace, last_assertion.backtrace, desc
      end
    end

    should "check if the model was destroyed with assert_destroyed and " \
           "assert_not_destroyed" do
      assert_result_is(false, @model){ |m| assert_destroyed m }
      assert_result_is(true,  @model){ |m| assert_not_destroyed m }

      @model.destroy

      assert_result_is(true,  @model){ |m| assert_destroyed m }
      assert_result_is(false, @model){ |m| assert_not_destroyed m }
    end

    should "check if a model's field was saved with assert_field_saved and " \
           "assert_not_field_saved" do
      assert_result_is(false, @model){ |m| assert_field_saved m, :name }
      assert_result_is(true,  @model){ |m| assert_not_field_saved m, :name }

      assert_result_is(false, @model){ |m| assert_field_saved m, :name, 'Test' }
      assert_result_is(true,  @model){ |m| assert_not_field_saved m, :name, 'Test' }

      @model.fields = { :name => 'Joe' }
      @model.save

      assert_result_is(true,  @model){ |m| assert_field_saved m, :name }
      assert_result_is(true,  @model){ |m| assert_field_saved m, :name, 'Joe' }
      assert_result_is(false, @model){ |m| assert_field_saved m, :name, 'Test' }

      assert_result_is(false, @model){ |m| assert_not_field_saved m, :name }
      assert_result_is(false, @model){ |m| assert_not_field_saved m, :name, 'Joe' }
      assert_result_is(true,  @model){ |m| assert_not_field_saved m, :name, 'Test' }
    end

  end

  class FakeTestRecord
    include MR::FakeRecord

    attribute :name, :string
  end

  class FakeTestModel
    include MR::Model
    record_class FakeTestRecord

    field_reader :id
    field_accessor :name
  end

end
