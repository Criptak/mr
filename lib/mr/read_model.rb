require 'mr/record'

module MR

  module ReadModel

    def self.new(&block)
      block ||= proc{ }
      klass = Class.new{ include MR::ReadModel }
      klass.class_eval(&block)
      klass
    end

    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        include InstanceMethods
        include self.read_model_interface_module
      end
    end

    module InstanceMethods

      def initialize(record_or_attributes)
        attributes = if record_or_attributes.kind_of?(Hash)
          record_or_attributes
        elsif record_or_attributes.kind_of?(MR::Record)
          record_or_attributes.attributes
        else
          raise MR::InvalidRecordError.new(record_or_attributes)
        end
        attributes.each do |name, value|
          self.instance_variable_set("@#{name}", value)
          mod = self.class.read_model_interface_module
          mod.class_eval{ attr_reader(name) }
        end
      end

    end

    module ClassMethods

      def read_model_interface_module
        @read_model_interface_module ||= Module.new
      end

    end

  end

end
