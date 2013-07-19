require 'mr/factory'
require 'mr/factory/apply_args'
require 'mr/factory/record_stack'

module MR; end
module MR::Factory

  class RecordFactory
    include ApplyArgs

    def initialize(record_class, &block)
      @record_class = record_class
      @defaults     = {}
      self.instance_eval(&block) if block
    end

    def instance(args = nil)
      @record_class.new.tap{ |record| apply_args(record, args) }
    end

    def instance_stack(args = nil)
      MR::Factory::RecordStack.new(self.instance(args))
    end

    def apply_args(record, args = nil)
      super record, build_defaults.merge(symbolize_hash(args || {}))
    end

    def default_args(value = nil)
      @defaults = symbolize_hash(value) if value
      @defaults
    end

    private

    def build_defaults
      @columns ||= non_association_columns(@record_class)
      column_defaults = @columns.inject({}) do |a, column|
        a.merge(column.name.to_sym => MR::Factory.send(column.type))
      end
      column_defaults.merge(@defaults)
    end

    def apply_args_to_associations!(record, args)
      one_to_one_associations_with_args(record, args).each do |association|
        associated_record = get_associated_record(record, association)
        association_args  = args.delete(association.reflection.name.to_sym)
        apply_args!(associated_record, association_args) if associated_record
      end
    end

    def get_associated_record(record, association)
      record.send(association.reflection.name) || begin
        new_record = RecordFactory.new(association.klass).instance
        record.send("#{association.reflection.name}=", new_record)
      end
    end

    def one_to_one_associations_with_args(record, args)
      record.class.reflect_on_all_associations.select do |reflection|
        hash_key?(args, reflection.name) && !reflection.collection?
      end.map do |reflection|
        record.association(reflection.name)
      end
    end

    def non_association_columns(record_class)
      association_columns = belongs_to_association_columns(record_class)
      record_class.columns.reject do |column|
        column.primary || association_columns.include?(column.name)
      end
    end

    def belongs_to_association_columns(record_class)
      associations = record_class.reflect_on_all_associations.select(&:belongs_to?)
      polymorphic_associations = associations.select{|a| a.options[:polymorphic] }
      associations.map(&:foreign_key) + polymorphic_associations.map(&:foreign_type)
    end

  end

end
