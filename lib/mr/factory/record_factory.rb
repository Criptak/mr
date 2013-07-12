require 'mr/factory'
require 'mr/factory/apply_args'
require 'mr/stack/record_stack'

module MR; end
module MR::Factory

  class RecordFactory
    include ApplyArgs

    def initialize(record_class, defaults = nil)
      @record_class = record_class
      @passed_default_args = symbolize_hash(defaults || {})
    end

    def instance(args = nil)
      @record_class.new.tap{ |record| apply_args(record, args) }
    end

    def instance_stack(args = nil)
      MR::Stack::RecordStack.new(@record_class).tap do |stack|
        apply_args(stack.record, args)
      end
    end

    def apply_args(record, args = nil)
      args ||= {}
      super record, default_args.merge(symbolize_hash(args))
    end

    private

    def default_args
      @columns ||= non_association_columns(@record_class)
      column_defaults = @columns.inject({}) do |a, column|
        a.merge(column.name.to_sym => MR::Factory.send(column.type))
      end
      column_defaults.merge(@passed_default_args)
    end

    def apply_args_to_associations!(record, args)
      one_to_one_associations_with_args(record, args).each do |association|
        associated_record = record.send(association.name)
        association_args  = args.delete(association.name.to_sym)
        apply_args!(associated_record, association_args) if associated_record
      end
    end

    def one_to_one_associations_with_args(record, args)
      record.class.reflect_on_all_associations.select do |reflection|
        hash_key?(args, reflection.name) && !reflection.collection?
      end
    end

    def non_association_columns(record_class)
      association_columns = belongs_to_association_columns(record_class)
      record_class.columns.reject do |column|
        column.primary || association_columns.include?(column.name)
      end
    end

    def belongs_to_association_columns(record_class)
      record_class.reflect_on_all_associations.select(&:belongs_to?).map(&:foreign_key)
    end

  end

end
