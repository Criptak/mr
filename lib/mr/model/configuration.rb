require 'ns-options'
require 'mr/record'

module MR; end
module MR::Model

  module Configuration

    # `MR::Model::Configuration` is a mixin that provides a model's base
    # configuration. This includes reading/writing a model class' `record_class`
    # and reading/writing a model's `record`. These operations validate what
    # is being written to avoid confusing errors. The `Configuration` mixin is
    # a base mixin for all the other model mixins.
    #
    # * Use the `record` protected method to access the record instance.
    # * Use the `set_record` private method to write a record value.

    def self.included(klass)
      klass.class_eval do
        include NsOptions
        options :configuration do
          option :record_class
        end
        extend ClassMethods
        include InstanceMethods
      end
    end

    module InstanceMethods

      def record_class
        self.class.record_class
      end

      protected

      def record
        @record || raise(NoRecordError.new(caller))
      end

      private

      def configuration
        self.class.configuration
      end

      def set_record(record)
        raise InvalidRecordError unless record.kind_of?(MR::Record)
        @record       = record
        @record.model = self
      end

    end

    module ClassMethods

      def record_class(*args)
        set_record_class(*args) unless args.empty?
        configuration.record_class || raise(NoRecordClassError.new(caller))
      end

      private

      def set_record_class(value)
        raise ArgumentError, "must be a MR::Record" unless value < MR::Record
        configuration.record_class = value
        value.model_class = self
      end

    end

  end

  InvalidRecordError = Class.new(ArgumentError)

  class NoRecordError < RuntimeError
    def initialize(called_from = nil)
      super "a record hasn't been set"
      set_backtrace(called_from) if called_from
    end
  end

  class NoRecordClassError < RuntimeError
    def initialize(called_from = nil)
      super "a record class hasn't been set"
      set_backtrace(called_from) if called_from
    end
  end

end
