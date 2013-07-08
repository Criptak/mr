require 'mr/factory'
require 'mr/stack/record_stack'

module MR; end
module MR::Factory

  class RecordFactory

    def initialize(record_class, defaults = nil)
      @record_class = record_class
      @defaults = StringKeyHash.new(defaults || {})
    end

    def instance(attrs = nil)
      @record_class.new(build_attributes(attrs))
    end

    def instance_stack(attrs = nil)
      MR::Stack::RecordStack.new(@record_class).tap do |stack|
        stack.record.attributes = build_attributes(attrs)
      end
    end

    def default_attributes
      columns = non_association_columns(@record_class)
      column_defaults = columns.inject({}) do |a, column|
        a.merge(column.name => MR::Factory.send(column.type))
      end
      column_defaults.merge(@defaults)
    end

    private

    def non_association_columns(record_class)
      associations = record_class.reflect_on_all_associations.select do |a|
        a.macro == :belongs_to
      end
      record_class.columns.reject do |column|
        column.primary || associations.detect{|a| a.foreign_key == column.name }
      end
    end

    def build_attributes(attrs)
      attrs = StringKeyHash.new(attrs || {})
      self.default_attributes.merge(attrs)
    end

  end

end
