require 'active_support/core_ext'
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
      @association_cache ||= {}
      @association_cache[name.to_sym] ||= begin
        reflection = self.class.reflections.find(name)
        reflection.association_class.new(self, reflection)
      end
    end

    module ClassMethods

      def reflections
        @reflections ||= MR::FakeRecord::ReflectionSet.new
      end

      def belongs_to(name, class_name)
        self.reflections.add_belongs_to(name, class_name, self)
      end

      def polymorphic_belongs_to(name)
        self.reflections.add_polymorphic_belongs_to(name, self)
      end

      def has_one(name, class_name)
        self.reflections.add_has_one(name, class_name, self)
      end

      def has_many(name, class_name)
        self.reflections.add_has_many(name, class_name, self)
      end

      # ActiveRecord methods

      def reflect_on_all_associations(type = nil)
        self.reflections.all(type)
      end

    end

  end

  class ReflectionSet
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
      reflection = Reflection.new(:belongs_to, name, {
        :class_name  => class_name,
        :foreign_key => "#{name}_id"
      })
      reflection.define_accessor_on(fake_record_class)
      @belongs_to[name.to_s] = reflection
    end

    def add_polymorphic_belongs_to(name, fake_record_class)
      reflection = Reflection.new(:belongs_to, name, {
        :foreign_type => "#{name}_type",
        :foreign_key  => "#{name}_id",
        :polymorphic  => true
      })
      reflection.define_accessor_on(fake_record_class)
      @belongs_to[name.to_s] = reflection
    end

    def add_has_one(name, class_name, fake_record_class)
      reflection = Reflection.new(:has_one, name, :class_name => class_name)
      reflection.define_accessor_on(fake_record_class)
      @has_one[name.to_s] = reflection
    end

    def add_has_many(name, class_name, fake_record_class)
      reflection = Reflection.new(:has_many, name, :class_name => class_name)
      reflection.define_accessor_on(fake_record_class)
      @has_many[name.to_s] = reflection
    end
  end

  class Reflection
    attr_reader :reader_method_name, :writer_method_name

    # ActiveRecord methods
    attr_reader :name, :macro, :options
    attr_reader :foreign_key, :foreign_type
    attr_reader :association_class

    BELONGS_TO_ASSOC_PROC = proc do |r|
      r.options[:polymorphic] ? PolymorphicBelongsToAssociation : BelongsToAssociation
    end
    ASSOCIATION_CLASS = {
      :belongs_to => BELONGS_TO_ASSOC_PROC,
      :has_one    => proc{ HasOneAssociation },
      :has_many   => proc{ HasManyAssociation }
    }.freeze

    def initialize(macro, name, options = nil)
      @macro   = macro.to_sym
      @name    = name
      @options = options || {}
      @class_name   = @options[:class_name]
      @foreign_key  = @options[:foreign_key]
      @foreign_type = @options[:foreign_type]

      @reader_method_name = name.to_s
      @writer_method_name = "#{@reader_method_name}="
      @association_class = ASSOCIATION_CLASS[@macro].call(self)
    end

    # ActiveRecord method
    def klass
      @klass ||= (@class_name.to_s.constantize if @class_name)
    end

    def define_accessor_on(fake_record_class)
      reflection = self
      fake_record_class.class_eval do

        define_method(reflection.reader_method_name) do
          self.association(reflection.name).read
        end
        define_method(reflection.writer_method_name) do |value|
          self.association(reflection.name).write(value)
        end

      end
    end

    def <=>(other)
      if other.kind_of?(self.class)
        [ self.macro,  self.options[:polymorphic],  self.name ].map(&:to_s) <=>
        [ other.macro, other.options[:polymorphic], other.name ].map(&:to_s)
      else
        super
      end
    end
  end

  class Association
    # ActiveRecord method
    attr_reader :reflection

    def initialize(owner, reflection)
      @owner = owner
      @reflection = reflection
      @ivar_name = "@#{@reflection.name}"
    end

    def read;         raise NotImplementedError; end
    def write(value); raise NotImplementedError; end

    # ActiveRecord method
    def klass
      self.reflection.klass
    end

    def <=>(other)
      other.kind_of?(Association) ? self.reflection <=> other.reflection : super
    end
  end

  class OneToOneAssociation < Association
    def read
      @owner.instance_variable_get(@ivar_name)
    end

    def write(value)
      @owner.instance_variable_set(@ivar_name, value)
      write_attributes(value || NULL_RECORD)
      value
    end

    private

    def write_attributes(associated_fake_record); end

    NullRecord  = Struct.new(:id, :class)
    NullClass   = Struct.new(:name)
    NULL_RECORD = NullRecord.new(nil, NullClass.new)
  end

  class OneToManyAssociation < Association
    def read
      @owner.instance_variable_get(@ivar_name) ||
      @owner.instance_variable_set(@ivar_name, [])
    end

    def write(value)
      @owner.instance_variable_set(@ivar_name, [*value].compact)
    end
  end

  class BelongsToAssociation < OneToOneAssociation
    def write_attributes(associated_fake_record)
      super
      associated_id = associated_fake_record.id
      @owner.send("#{self.reflection.foreign_key}=", associated_id)
    end
  end

  class PolymorphicBelongsToAssociation < BelongsToAssociation
    def write_attributes(associated_fake_record)
      super
      associated_type = associated_fake_record.class.name
      @owner.send("#{self.reflection.foreign_type}=", associated_type)
    end

    def klass
      class_name = @owner.send(self.reflection.foreign_type)
      class_name.constantize if class_name
    end
  end

  HasOneAssociation  = OneToOneAssociation
  HasManyAssociation = OneToManyAssociation

end
