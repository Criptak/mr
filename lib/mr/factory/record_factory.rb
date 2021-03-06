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

    def instance(args = nil, &block)
      apply_args(@record_class.new, args).tap(&(block || proc{ }))
    end

    def saved_instance(args = nil, &block)
      record = self.instance(args, &block).tap(&:save!)
      record.reset_save_called if record.kind_of?(MR::FakeRecord)
      record
    end

    def instance_stack(args = nil, &block)
      MR::Factory::RecordStack.new(self.instance(args)).tap(&(block || proc{ }))
    end

    def default_args(value = nil)
      @defaults = stringify_hash(value) if value
      @defaults
    end

    private

    def apply_args(record, args = nil)
      apply_args!(record, column_args)
      apply_args!(record, @defaults)
      apply_args!(record, stringify_hash(args || {}))
      record
    end

    def column_args
      @columns ||= non_association_columns(@record_class)
      @columns.inject({}) do |a, column|
        column_type = column.type || column.sql_type
        if !column_type.nil? && MR::Factory.respond_to?(column_type)
          a.merge(column.name.to_s => MR::Factory.send(column_type))
        else
          a
        end
      end
    end

    def apply_args_to_associations!(record, args)
      one_to_one_associations_with_args(record, args).each do |association|
        associated_record = get_associated_record(record, association)
        association_args  = args.delete(association.reflection.name.to_s)
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
      reflections = record.class.reflect_on_all_associations(:belongs_to) +
                    record.class.reflect_on_all_associations(:has_one)
      reflections.map{ |r| record.association(r.name) if hash_key?(args, r.name) }.compact
    end

    def non_association_columns(record_class)
      association_columns = belongs_to_association_columns(record_class)
      record_class.columns.reject do |column|
        column.primary || association_columns.include?(column.name)
      end
    end

    def belongs_to_association_columns(record_class)
      reflections = record_class.reflect_on_all_associations(:belongs_to)
      polymorphic_reflections = reflections.select{ |a| a.options[:polymorphic] }
      reflections.map(&:foreign_key) + polymorphic_reflections.map(&:foreign_type)
    end

  end

end
