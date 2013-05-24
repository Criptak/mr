require 'ostruct'
require 'test/support/test_models'

class AssociationsContext < Assert::Context
  setup do

    @klass = Class.new do
      attr_reader :record
      def initialize
        @record = OpenStruct.new({
          :test_model_belongs_to => TestFakeRecord.new({ :id => 3 }),
          :test_model_has_many   => [
            TestFakeRecord.new({ :id => 4 })
          ]
        })
      end
    end

  end

end
