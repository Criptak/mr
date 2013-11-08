require 'mr/model/configuration'

module MR; end
module MR::Model

  module Associations

    def self.included(klass)
      klass.class_eval do
        include MR::Model::Configuration
        extend ClassMethods
      end
    end

    module ClassMethods

      def associations
        @associations ||= MR::Model::AssociationSet.new
      end

      def belongs_to(*names)
        names.each do |name|
          self.associations.add_belongs_to(name, self)
        end
      end

      def polymorphic_belongs_to(*names)
        names.each do |name|
          self.associations.add_polymorphic_belongs_to(name, self)
        end
      end

      def has_one(*names)
        names.each do |name|
          self.associations.add_has_one(name, self)
        end
      end

      def has_many(*names)
        names.each do |name|
          self.associations.add_has_many(name, self)
        end
      end

    end

  end

  class AssociationSet
    attr_reader :belongs_to, :polymorphic_belongs_to
    attr_reader :has_one, :has_many

    def initialize
      @belongs_to = []
      @polymorphic_belongs_to = []
      @has_one  = []
      @has_many = []
    end

    def add_belongs_to(name, model_class)
      association = BelongsToAssociation.new(name, model_class.record_class)
      association.define_accessor_on(model_class)
      @belongs_to << association
    end

    def add_polymorphic_belongs_to(name, model_class)
      association = PolymorphicBelongsToAssociation.new(name, model_class.record_class)
      association.define_accessor_on(model_class)
      @polymorphic_belongs_to << association
    end

    def add_has_one(name, model_class)
      association = HasOneAssociation.new(name, model_class.record_class)
      association.define_accessor_on(model_class)
      @has_one << association
    end

    def add_has_many(name, model_class)
      association = HasManyAssociation.new(name, model_class.record_class)
      association.define_accessor_on(model_class)
      @has_many << association
    end

  end

  class Association
    attr_reader :name
    attr_reader :reader_method_name, :writer_method_name

    def initialize(name, record_class)
      @name = name.to_s
      @reader_method_name = @name
      @writer_method_name = "#{@name}="
      @association_reader_name = @name
      @association_writer_name = "#{@name}="
      @record_class = record_class
    end

    def type;         raise NotImplementedError; end
    def type_display; raise NotImplementedError; end

    def define_accessor_on(model_class)
      validate!
      association = self
      model_class.class_eval do

        define_method(association.reader_method_name) do
          association.read(record)
        end

        define_method(association.writer_method_name) do |value|
          begin
            association.write(value, self, record){ |m| m.record }
          rescue BadAssociationValueError => exception
            raise ArgumentError, exception.message, caller
          end
        end

      end
    end

    private

    def validate!
      reflection = @record_class.reflect_on_association(@name.to_sym) ||
                   @record_class.reflect_on_association(@name)
      if !(reflection && valid_record_association?(reflection))
        raise NoRecordAssociationError.new(@name, type_display, reflection)
      end
    end

    def valid_record_association?(record_association)
      record_association.macro == type
    end
  end

  class OneToOneAssociation < Association
    def read(record)
      if associated_record = record.send(@association_reader_name)
        associated_record.model_class.new(associated_record)
      end
    end

    def write(value, model, record, &block)
      raise BadAssociationValueError.new(value) if value && !value.kind_of?(MR::Model)
      association_record = model.instance_exec(value, &block) if value
      record.send(@association_writer_name, association_record)
    end
  end

  class OneToManyAssociation < Association
    def read(record)
      (record.send(@association_reader_name) || []).map do |associated_record|
        associated_record.model_class.new(associated_record)
      end
    end

    def write(values, model, record, &block)
      associated_records = [*values].compact.map do |value|
        raise BadAssociationValueError.new(value) if !value.kind_of?(MR::Model)
        model.instance_exec(value, &block)
      end
      record.send(@association_writer_name, associated_records)
    end
  end

  class BelongsToAssociation < OneToOneAssociation
    def type;         :belongs_to;  end
    def type_display; 'belongs to'; end
  end

  class HasOneAssociation < OneToOneAssociation
    def type;         :has_one;  end
    def type_display; 'has one'; end
  end

  class HasManyAssociation < OneToManyAssociation
    def type;         :has_many;  end
    def type_display; 'has many'; end
  end

  class PolymorphicBelongsToAssociation < BelongsToAssociation
    def type_display; 'polymorphic belongs to'; end

    private

    def valid_record_association?(record_association)
      super && record_association.options[:polymorphic]
    end
  end

  class NoRecordAssociationError < RuntimeError
    def initialize(name, type, ar_reflection)
      if ar_reflection
        super "the #{name.inspect} association on the record is not a #{type}"
      else
        super "a #{name.inspect} #{type} association doesn't exist on the record"
      end
    end
  end

  class BadAssociationValueError < RuntimeError
    def initialize(value)
      super "#{value.inspect} is not a kind of MR::Model"
    end
  end

end
