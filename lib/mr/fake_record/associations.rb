require 'mr/fake_record/attributes'

module MR; end
module MR::FakeRecord

  module Associations

    def self.included(klass)
      klass.class_eval do
        include MR::FakeRecord::Attributes
        extend ClassMethods
      end
    end

    # ActiveRecord methods

    def association(name)
      self.class.associations.find(name)
    end

    module ClassMethods

      def associations
        @associations ||= MR::FakeRecord::AssociationSet.new
      end

      def belongs_to(name, class_name)
        self.associations.add_belongs_to(name, class_name, self)
      end

      def polymorphic_belongs_to(name)
        self.associations.add_polymorphic_belongs_to(name, self)
      end

      def has_one(name, class_name)
        self.associations.add_has_one(name, class_name, self)
      end

      def has_many(name, class_name)
        self.associations.add_has_many(name, class_name, self)
      end

      # ActiveRecord methods

      def reflect_on_all_associations(type = nil)
        self.associations.all(type).map(&:reflection)
      end

    end

  end

  class AssociationSet
    def initialize
      @belongs_to = {}
      @has_one  = {}
      @has_many = {}
    end

    def belongs_to
      @belongs_to.values.sort
    end

    def has_one
      @has_one.values.sort
    end

    def has_many
      @has_many.values.sort
    end

    def find(name)
      @belongs_to[name.to_s] || @has_one[name.to_s] || @has_many[name.to_s]
    end

    def all(type = nil)
      case type
      when :belongs_to, :has_one, :has_many
        self.send(type)
      else
        self.belongs_to + self.has_one + self.has_many
      end
    end

    def add_belongs_to(name, class_name, fake_record_class)
      association = BelongsToAssociation.new(name, class_name)
      association.define_accessor_on(fake_record_class)
      @belongs_to[name.to_s] = association
    end

    def add_polymorphic_belongs_to(name, fake_record_class)
      association = PolymorphicBelongsToAssociation.new(name)
      association.define_accessor_on(fake_record_class)
      @belongs_to[name.to_s] = association
    end

    def add_has_one(name, class_name, fake_record_class)
      association = HasOneAssociation.new(name, class_name)
      association.define_accessor_on(fake_record_class)
      @has_one[name.to_s] = association
    end

    def add_has_many(name, class_name, fake_record_class)
      association = HasManyAssociation.new(name, class_name)
      association.define_accessor_on(fake_record_class)
      @has_many[name.to_s] = association
    end
  end

  class Association
    attr_reader :reader_method_name, :writer_method_name
    attr_reader :ivar_name

    # ActiveRecord methods
    attr_reader :reflection

    def initialize(name, options = nil)
      @reflection = Reflection.new(name, options)
      @reader_method_name = name.to_s
      @writer_method_name = "#{@reader_method_name}="
      @ivar_name = "@#{@reader_method_name}"
    end

    def <=>(other)
      if other.kind_of?(Association)
        self.reflection <=> other.reflection
      else
        super
      end
    end

    # ActiveRecord method
    def klass
      self.reflection.klass
    end
  end

  class OneToOneAssociation < Association
    def initialize(name, options = nil)
      @foreign_key = "#{name.to_s.downcase}_id"
      super(name, options.merge(:foreign_key => @foreign_key))
    end

    def write_attributes(associated_fake_record, fake_record)
      fake_record.send("#{@foreign_key}=", associated_fake_record.id)
    end

    def define_accessor_on(fake_record_class)
      association = self
      fake_record_class.class_eval do

        define_method(association.reader_method_name) do
          self.instance_variable_get(association.ivar_name)
        end
        define_method(association.writer_method_name) do |value|
          self.instance_variable_set(association.ivar_name, value)
          association.write_attributes(value || NULL_RECORD, self)
          value
        end

      end
    end

    NullRecord  = Struct.new(:id, :class)
    NullClass   = Struct.new(:name)
    NULL_RECORD = NullRecord.new(nil, NullClass.new)
  end

  class OneToManyAssociation < Association
    def define_accessor_on(fake_record_class)
      association = self
      fake_record_class.class_eval do

        define_method(association.reader_method_name) do
          self.instance_variable_get(association.ivar_name) ||
          self.instance_variable_set(association.ivar_name, [])
        end
        define_method(association.writer_method_name) do |value|
          self.instance_variable_set(association.ivar_name, [*value].compact)
        end

      end
    end
  end

  class BelongsToAssociation < OneToOneAssociation
    def initialize(name, class_name, options = nil)
      options ||= {}
      super(name, options.merge(:type => :belongs_to, :class_name => class_name))
    end
  end

  class PolymorphicBelongsToAssociation < BelongsToAssociation
    def initialize(name)
      @foreign_type = "#{name.to_s.downcase}_type"
      super(name, nil, :polymorphic => true, :foreign_type => @foreign_type)
    end

    def write_attributes(associated_fake_record, fake_record)
      super
      fake_record.send("#{@foreign_type}=", associated_fake_record.class.to_s)
    end
  end

  class HasOneAssociation < OneToOneAssociation
    def initialize(name, class_name)
      super(name, :type => :has_one, :class_name => class_name)
    end
  end

  class HasManyAssociation < OneToManyAssociation
    def initialize(name, class_name)
      super(name, :type => :has_many, :class_name => class_name)
    end
  end

  class Reflection
    # All the methods on this class are ActiveRecord methods

    attr_reader :name, :macro, :options
    attr_reader :foreign_key, :foreign_type

    def initialize(name, options = nil)
      @name    = name
      @options = options || {}
      @macro   = options.delete(:type)
      @class_name = options[:class_name].to_s
      @foreign_key  = options[:foreign_key]
      @foreign_type = options[:foreign_type]
    end

    def klass
      @klass ||= @class_name.constantize
    end

    def <=>(other)
      if other.kind_of?(self.class)
        a = [ self.macro,  self.options[:polymorphic],  self.name ].map(&:to_s)
        b = [ other.macro, other.options[:polymorphic], other.name ].map(&:to_s)
        a <=> b
      else
        super
      end
    end

  end

end
