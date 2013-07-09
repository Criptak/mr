require 'mr/factory'
require 'mr/stack/record_stack'

module MR; end
module MR::Factory

  class RecordFactory

    def initialize(record_class, defaults = nil)
      @record_class = record_class
      @defaults = StringKeyHash.new(defaults || {})
    end

    def instance(args = nil)
      @record_class.new.tap{ |record| apply_args(record, args) }
    end

    def instance_stack(args = nil)
      MR::Stack::RecordStack.new(@record_class).tap do |stack|
        apply_args(stack.record, args)
      end
    end

    def default_attributes
      @columns ||= non_association_columns(@record_class)
      column_defaults = @columns.inject({}) do |a, column|
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

    def apply_args(record, args)
      args = StringKeyHash.new(args || {})
      apply_args!(record, self.default_attributes.merge(args))
    end

    def apply_args!(record, args)
      args = args.dup
      apply_args_to_associations(record, args)
      args.each{ |name, value| record.send("#{name}=", value) }
    end

    def apply_args_to_associations(record, args)
      record.class.reflect_on_all_associations.select do |association|
        one_to_one_with_args?(association, args)
      end.each do |association|
        associated_record = record.send(association.name)
        association_args  = args.delete(association.name.to_s)
        apply_args!(associated_record, association_args) if associated_record
      end
    end

    def one_to_one_with_args?(association, args)
      args[association.name.to_s].kind_of?(Hash) &&
        [ :belongs_to, :has_one ].include?(association.macro)
    end

  end

end
