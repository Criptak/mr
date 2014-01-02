require 'mr/factory'
require 'mr/fake_record_associations'
require 'mr/record'
require 'ns-options'
require 'set'
require 'thread'

module MR; end
module MR::FakeRecord

  def self.included(klass)
    klass.class_eval do
      include MR::Record
      include NsOptions
      extend ClassMethods

      options :fr_config do
        option :attributes,   Set, :default => []
        option :associations, Set, :default => []
      end

      attribute :id, :primary_key

      attr_reader :saved_attributes, :previous_attributes
    end
  end

  def initialize(attrs = nil)
    @previous_attributes = {}
    @saved_attributes = self.attributes.dup
    self.attributes   = attrs || {}
  end

  def attributes
    self.class.attributes.inject({}) do |h, attribute|
      h.merge(attribute.name.to_sym => self.send(attribute.name))
    end
  end

  def attributes=(values)
    values.each do |name, value|
      self.send "#{name}=", value
    end
  end

  def save!
    self.id ||= MR::Factory.primary_key(self.class)
    (self.created_at ||= Time.now) if self.respond_to?(:created_at=)
    (self.updated_at   = Time.now) if self.respond_to?(:updated_at=)
    @previous_attributes = @saved_attributes.dup
    @saved_attributes.merge!(self.attributes.dup)
  end

  def destroy
    @destroyed = true
  end

  def transaction(&block)
    self.class.transaction(&block)
  end

  def new_record?
    !self.id
  end

  def errors
    @errors ||= ErrorSet.new
  end

  def valid?
    self.errors.empty?
  end

  def destroyed?
    !!@destroyed
  end

  def association(name)
    association = self.class.associations.detect{ |a| a.name.to_s == name.to_s }
    association.dup.tap{ |a| a.record = self }
  end

  def ==(other)
    if other.kind_of?(self.class)
      self.id == other.id
    else
      super
    end
  end

  module ClassMethods

    def model_class(value = nil)
      (@model_class = value) if value
      @model_class
    end

    def attribute(name, type)
      attribute = AttributeOld.new(name, type)
      attr_accessor attribute.name
      define_method("#{attribute.name}_changed?") do
        self.send(attribute.name) != @saved_attributes[attribute.name.to_sym]
      end
      self.fr_config.attributes << attribute
    end

    def attributes
      self.fr_config.attributes
    end
    alias :columns :attributes

    def column_names
      self.attributes.map{ |a| a.name.to_s }.sort
    end

    def associations
      self.fr_config.associations
    end
    alias :reflect_on_all_associations :associations

    def reflect_on_association(name)
      self.associations.detect{ |a| a.name.to_s == name.to_s }
    end

    def belongs_to(name, fake_record_class_name, options = nil)
      options ||= {}
      options[:class_name] = fake_record_class_name
      association = BelongsToOld.new(name, options)
      association.define_methods(self)
      self.fr_config.associations << association
    end

    def has_many(name, fake_record_class_name)
      association = HasManyOld.new(name, :class_name => fake_record_class_name)
      association.define_methods(self)
      self.fr_config.associations << association
    end

    def has_one(name, fake_record_class_name)
      association = HasOneOld.new(name, :class_name => fake_record_class_name)
      association.define_methods(self)
      self.fr_config.associations << association
    end

    def polymorphic_belongs_to(name, options = nil)
      association = PolymorphicBelongsToOld.new(name, options)
      association.define_methods(self)
      self.fr_config.associations << association
    end

    def transaction(&block)
      yield
    end

  end

  class AttributeOld
    attr_reader :name, :type, :primary
    def initialize(name, type)
      @name = name.to_s
      @type = type.to_sym
      @primary = (@type == :primary_key)
    end

    def ==(other)
      self.name == other.name
    end

    def <=>(other)
      self.name <=> other.name
    end
  end

  class ErrorSet
    attr_reader :messages

    def initialize
      @messages = {}
    end

    def add(attribute, message)
      @messages[attribute.to_s] ||= []
      @messages[attribute.to_s] << message
    end

    def empty?
      @messages.empty?
    end
  end

end
