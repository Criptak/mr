require 'mr/factory'

module MR; end
module MR::Factory

  class RecordFactory

    def initialize(record_class, defaults = nil)
      @record_class = record_class
      @defaults     = StringKeyHash.new(defaults || {})
    end

    def instance(attrs = nil)
      attrs = StringKeyHash.new(attrs || {})
      @record_class.new(self.default_attributes.merge(attrs))
    end

    def default_attributes
      column_defaults = non_association_columns(@record_class).inject({}) do |a, column|
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

  end

end
