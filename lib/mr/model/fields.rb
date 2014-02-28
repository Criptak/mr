require 'mr/model/configuration'

module MR; end
module MR::Model

  module Fields

    def self.included(klass)
      klass.class_eval do
        include MR::Model::Configuration
        extend ClassMethods
      end
    end

    def fields
      self.class.fields.read_all(record)
    end

    def fields=(values)
      raise(ArgumentError, "must be a hash") unless values.kind_of?(Hash)
      self.class.fields.batch_write(values, record)
    rescue NoFieldError => exception
      exception.set_backtrace(caller)
      raise exception
    end

    module ClassMethods

      def fields
        @fields ||= MR::Model::FieldSet.new
      end

      def field_reader(*names)
        names.each do |name|
          self.fields.add_reader(name, self)
        end
      end

      def field_writer(*names)
        names.each do |name|
          self.fields.add_writer(name, self)
        end
      end

      def field_accessor(*names)
        field_reader(*names)
        field_writer(*names)
      end

    end

  end

  class FieldSet
    include Enumerable

    def initialize
      @fields = {}
    end

    def find(name)
      @fields[name.to_s] || raise(NoFieldError, "the '#{name}' field doesn't exist")
    end

    def get(name)
      @fields[name.to_s] ||= Field.new(name)
    end

    def each(&block)
      @fields.values.each(&block)
    end

    def read_all(record)
      @fields.values.inject({}) do |h, field|
        h.merge(field.name => field.read(record))
      end
    end

    def batch_write(values, record)
      values.each{ |name, value| find(name).write(value, record) }
    end

    def add_reader(name, model_class)
      get(name).define_reader_on(model_class)
    end

    def add_writer(name, model_class)
      get(name).define_writer_on(model_class)
    end

    private

    def stringify_hash(hash)
      hash.inject({}){ |h, (k, v)| h.merge(k.to_s => v) }
    end

  end

  class Field
    attr_reader :name
    attr_reader :reader_method_name, :was_method_name, :changed_method_name
    attr_reader :writer_method_name

    def initialize(name)
      @name = name.to_s
      @reader_method_name  = @name
      @was_method_name     = "#{@name}_was"
      @changed_method_name = "#{@name}_changed?"
      @writer_method_name  = "#{@reader_method_name}="
      @attribute_reader_method_name = @reader_method_name
      @attribute_writer_method_name = @writer_method_name
      @attribute_was_method_name = "#{@reader_method_name}_was"
      @attribute_changed_method_name = "#{@reader_method_name}_changed?"
    end

    def read(record)
      record.send(@attribute_reader_method_name)
    end

    def write(value, record)
      record.send(@attribute_writer_method_name, value)
    end

    def was(record)
      record.send(@attribute_was_method_name)
    end

    def changed?(record)
      record.send(@attribute_changed_method_name)
    end

    def define_reader_on(model_class)
      field = self
      model_class.class_eval do

        define_method(field.reader_method_name) do
          field.read(record)
        end
        define_method(field.changed_method_name) do
          field.changed?(record)
        end
        define_method(field.was_method_name) do
          field.was(record)
        end

      end
    end

    def define_writer_on(model_class)
      field = self
      model_class.class_eval do

        define_method(field.writer_method_name) do |value|
          field.write(value, record)
        end

      end
    end

  end

  NoFieldError = Class.new(RuntimeError)

end
