require 'assert'
require 'mr/fields'
require 'ostruct'
require 'test/support/test_models'

module MR::Fields

  class BaseTests < Assert::Context
    setup do

      @klass = Class.new do
        attr_reader :record
        def initialize
          @record = { :some_method => 'test' }
        end
      end

    end
  end

  class ReaderTests < BaseTests
    desc "MR::Fields::Reader"
    setup do
      Reader.new(@klass, :some_method)
    end

    should "have defined the reader method name on the klass" do
      instance = @klass.new

      assert_equal 'test', instance.some_method
      assert_not instance.respond_to?(:some_method=)
    end

  end

  class WriterTests < BaseTests
    desc "MR::Fields::Writer"
    setup do
      Writer.new(@klass, :something_else)
    end

    should "have defined the writer method name on the klass" do
      instance = @klass.new
      instance.something_else = 'another'

      assert_equal 'another', instance.record[:something_else]
      assert_not instance.respond_to?(:something_else)
    end

  end

end
