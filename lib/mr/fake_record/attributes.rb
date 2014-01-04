module MR; end
module MR::FakeRecord

  module Attributes

    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end

    attr_writer :saved_attributes

    def saved_attributes
      @saved_attributes ||= {}
    end

    # ActiveRecord methods

    def attributes
      self.class.attributes.read_all(self)
    end

    def attributes=(new_attributes)
      return unless new_attributes.is_a?(Hash)
      self.class.attributes.batch_write(new_attributes, self)
    end

    module ClassMethods

      def attributes
        @attributes ||= MR::FakeRecord::AttributeSet.new
      end

      def attribute(name, type)
        self.attributes.add(name, type, self)
      end

      # ActiveRecord methods

      def columns
        self.attributes.to_a
      end

    end

  end

  class AttributeSet
    include Enumerable

    def initialize
      @attributes = {}
    end

    def find(name)
      @attributes[name.to_s] || raise(NoAttributeError.new(name))
    end

    def each(&block)
      @attributes.values.each(&block)
    end

    def read_all(record)
      @attributes.values.inject({}) do |h, attribute|
        h.merge(attribute.name => attribute.read(record))
      end
    end

    def batch_write(new_attributes, record)
      new_attributes.each{ |name, value| find(name).write(value, record) }
    end

    def to_a
      @attributes.values.sort
    end

    def add(name, type, record_class)
      @attributes[name.to_s] = Attribute.new(name, type).tap do |attribute|
        attribute.define_on(record_class)
      end
    end

  end

  class Attribute
    attr_reader :name, :type
    attr_reader :reader_method_name, :writer_method_name, :changed_method_name

    # ActiveRecord methods
    attr_reader :primary

    def initialize(name, type)
      @name = name.to_s
      @type = type.to_sym
      @primary = (@type == :primary_key)

      @reader_method_name  = @name
      @writer_method_name  = "#{@reader_method_name}="
      @changed_method_name = "#{@reader_method_name}_changed?"
    end

    def read(record)
      record.send(@reader_method_name)
    end

    def write(value, record)
      record.send(@writer_method_name, value)
    end

    def changed?(record)
      read(record) != record.saved_attributes[@name]
    end

    def ==(other)
      self.name == other.name
    end

    def <=>(other)
      self.name <=> other.name
    end

    def define_on(record_class)
      attribute = self
      record_class.class_eval do

        attr_accessor attribute.reader_method_name
        define_method(attribute.changed_method_name) do
          attribute.changed?(self)
        end

      end
    end

  end

  class NoAttributeError < RuntimeError
    def initialize(attr_name)
      super "the '#{attr_name}' attribute doesn't exist"
    end
  end

end
