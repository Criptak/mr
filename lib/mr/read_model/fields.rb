require 'active_record'
require 'mr/read_model/data'
require 'mr/read_model/querying'

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
        h.merge({ field.name => field.read(data) })
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

    TYPES = {
      :boolean  => [ :boolean ],
      :binary   => [ :binary ],
      :date     => [ :date ],
      :datetime => [ :datetime, :timestamp ],
      :decimal  => [ :decimal ],
      :float    => [ :float ],
      :integer  => [ :integer, :primary_key ],
      :string   => [ :string, :text ],
      :time     => [ :time ]
    }.freeze
    VALID_TYPES = TYPES.values.flatten.freeze

    attr_reader :name, :type, :value
    attr_reader :method_name, :ivar_name

    def initialize(name, type)
      @name = name.to_s
      @type = type.to_sym
      raise BadFieldTypeError.new(@type) unless VALID_TYPES.include?(@type)
      @method_name     = @name
      @ivar_name       = "@#{@name}"
      @attribute_name  = @name
      @ar_column_class = nil
    end

    def read(data)
      @ar_column_class ||= determine_ar_column_class(data)
      type_cast(data[@attribute_name])
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
      if data.class.respond_to?(:columns)
        data.class.columns.first.class
      else
        ActiveRecord::ConnectionAdapters::Column
      end
    end

    def type_cast(value)
      return if value.nil?
      case @type
      when *TYPES[:string]   then value
      when *TYPES[:integer]  then @ar_column_class.value_to_integer(value)
      when *TYPES[:float]    then value.to_f
      when *TYPES[:decimal]  then @ar_column_class.value_to_decimal(value)
      when *TYPES[:datetime] then @ar_column_class.string_to_time(value)
      when *TYPES[:time]     then @ar_column_class.string_to_dummy_time(value)
      when *TYPES[:date]     then @ar_column_class.string_to_date(value)
      when *TYPES[:binary]   then @ar_column_class.binary_to_string(value)
      when *TYPES[:boolean]  then @ar_column_class.value_to_boolean(value)
      end
    end

  end

  class BadFieldTypeError < RuntimeError
    def initialize(type_key)
      super "#{type_key.to_s.inspect} is not a valid field type"
    end
  end

end
