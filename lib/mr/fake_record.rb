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
      include NsOptions
      extend ClassMethods
      include MR::Record

      options :fr_config do
        option :attributes,   Set, :default => []
        option :associations, Set, :default => []
      end

      attribute :id, :primary_key

      attr_reader :saved_attributes
    end
  end

  def initialize(attrs = nil)
    self.attributes = attrs || {}
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
    @saved_attributes  = self.attributes.dup
  end

  def destroy
    @destroyed = true
  end

  def transaction(&block)
    yield
  end

  def new_record?
    !self.id
  end

  def valid?
    true
  end

  def destroyed?
    !!@destroyed
  end

  def [](attribute_name)
    self.send(attribute_name)
  end

  def []=(attribute_name, value)
    self.send("#{attribute_name}=", value)
  end

  def ==(other)
    if other.kind_of?(self.class)
      self.id == other.id
    else
      super
    end
  end

  module ClassMethods

    def attribute(name, type)
      attribute = Attribute.new(name, type)
      attr_accessor attribute.name
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

    def belongs_to(name, fake_record_class_name, options = nil)
      association = BelongsTo.new(name, fake_record_class_name, options)
      association.define_methods(self)
      self.fr_config.associations << association
    end

    def has_many(name, fake_record_class_name)
      association = HasMany.new(name, fake_record_class_name)
      association.define_methods(self)
      self.fr_config.associations << association
    end

    def has_one(name, fake_record_class_name)
      association = HasOne.new(name, fake_record_class_name)
      association.define_methods(self)
      self.fr_config.associations << association
    end

  end

  class Attribute
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

end
