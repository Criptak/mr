require 'ostruct'
require 'test/support/models/fake_test_record'

module MR::Associations

  module TestHelpers

    def self.included(klass)
      klass.class_eval do
        setup{ define_fake_model_class_with_associations }
      end
    end

    private

    def define_fake_model_class_with_associations
      @fake_model_class = Class.new do
        attr_reader :record
        def initialize
          @record = OpenStruct.new({
            :test_model_belongs_to => FakeTestRecord.new(:id => 3),
            :test_model_has_many   => [ FakeTestRecord.new(:id => 4) ],
            :test_model_polymorphic_belongs_to => FakeTestRecord.new(:id => 5)
          })
        end
      end
    end

  end

end
