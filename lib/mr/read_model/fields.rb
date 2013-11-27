require 'mr/read_model/data'
require 'mr/read_model/querying'
require 'mr/type_converter'

module MR; end
module MR::ReadModel

  module Fields

    def self.included(klass)
      klass.class_eval do
        include MR::ReadModel::Data
        include MR::ReadModel::Querying
        extend ClassMethods
      end
    end

    def fields
      self.class.fields.read_all(data)
    end

    module ClassMethods

      def fields
        @fields ||= MR::ReadModel::FieldSet.new
      end

      def field(name, type, column = nil, &column_provider)
        fields.add(name, type, self)
        if column
          select("#{column} AS #{name}")
        elsif column_provider
          select{ |args| "#{column_provider.call(args)} AS #{name}" }
        end
      rescue BadFieldTypeError => exception
        raise ArgumentError, exception.message
      end

    end

  end

  class FieldSet
    include Enumerable

    def initialize
      @fields = []
    end

    def find(name)
      @fields.detect{ |f| f.name == name.to_s }
    end

    def read_all(data)
      inject({}) do |h, field|
        h.merge(field.name => field.read(data))
      end
    end

    def add(name, type, model_class = nil)
      @fields << Field.new(name, type).tap do |field|
        field.define_on(model_class) if model_class
      end
    end

    def each(&block)
      @fields.each(&block)
    end

  end

  class Field
    attr_reader :name, :type, :value
    attr_reader :method_name, :ivar_name

    def initialize(name, type)
      @name = name.to_s
      @type = type.to_sym
      raise BadFieldTypeError.new(@type) unless MR::TypeConverter.valid?(@type)
      @method_name     = @name
      @ivar_name       = "@#{@name}"
      @attribute_name  = @name
      @converter = nil
    end

    def read(data)
      @converter ||= MR::TypeConverter.new(determine_ar_column_class(data))
      @converter.convert(data[@attribute_name], @type)
    end

    def define_on(model_class)
      field = self
      model_class.class_eval do

        define_method(field.method_name) do
          instance_variable_get(field.ivar_name) ||
          instance_variable_set(field.ivar_name, field.read(data))
        end

      end
    end

    private

    def determine_ar_column_class(data)
      data.class.columns.first.class if data.class.respond_to?(:columns)
    end

  end

  class BadFieldTypeError < RuntimeError
    def initialize(type_key)
      super "#{type_key.to_s.inspect} is not a valid field type"
    end
  end

end
