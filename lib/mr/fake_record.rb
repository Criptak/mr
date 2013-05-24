require 'mr/record'
require 'ns-options'
require 'securerandom'
require 'set'

module MR; end
module MR::FakeRecord

  def self.included(klass)
    klass.class_eval do
      include NsOptions
      extend ClassMethods
      include MR::Record

      options :fr_config do
        option :attributes, Set, :default => []
      end

      attributes :id

      attr_reader :saved_attributes

    end
  end

  def initialize(attrs = nil)
    self.attributes = attrs || {}
  end

  def attributes
    self.class.fr_config.attributes.inject({}) do |h, attr_name|
      h.merge({ attr_name => self.send(attr_name) })
    end
  end

  def attributes=(values)
    values.each do |name, value|
      self.send "#{name}=", value
    end
  end

  def save!
    self.id ||= ::SecureRandom.random_number(100)
    (self.created_at ||= Time.now) if self.respond_to?(:created_at=)
    (self.updated_at = Time.now) if self.respond_to?(:updated_at=)
    @saved_attributes = self.attributes.dup
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

    def attributes(*args)
      args.each do |attr_name|
        attr_accessor attr_name
        self.fr_config.attributes << attr_name.to_sym
      end
    end

    def belongs_to(*args)
      args.each do |association_name|
        BelongsTo.new(association_name).define_methods(self)
      end
    end

    def has_many(*args)
      args.each do |association_name|
        HasMany.new(association_name).define_methods(self)
      end
    end

  end

  class BelongsTo
    attr_reader :reader_name, :writer_name, :ivar_name, :id_writer_name
    def initialize(name)
      @reader_name = name
      @writer_name = "#{name}="

      @ivar_name = "@#{name}"

      @id_writer_name = "#{name}_id="
    end

    def define_methods(klass)
      belongs_to = self
      klass.class_eval do

        attr_reader belongs_to.reader_name

        define_method(belongs_to.writer_name) do |model|
          self.instance_variable_set(belongs_to.ivar_name, model)

          if self.respond_to?(belongs_to.id_writer_name)
            self.send(belongs_to.id_writer_name, model.try(:id))
          end

          self.instance_variable_get(belongs_to.ivar_name)
        end

      end
    end
  end

  class HasMany
    attr_reader :reader_name, :ivar_name
    def initialize(name)
      @reader_name = name
      @ivar_name = "@#{name}"
    end

    def define_methods(klass)
      has_many = self
      klass.class_eval do

        define_method(has_many.reader_name) do
          if !self.instance_variable_get(has_many.ivar_name)
            self.instance_variable_set(has_many.ivar_name, [])
          end
          self.instance_variable_get(has_many.ivar_name)
        end

        attr_writer has_many.reader_name

      end
    end
  end

end
