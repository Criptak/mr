require 'active_record'

module MR

  class TypeConverter
    TYPES = [
      :binary,
      :boolean,
      :date,
      :datetime, :timestamp,
      :decimal,
      :float,
      :integer, :primary_key,
      :string, :text,
      :time
    ].freeze

    def self.valid?(type)
      TYPES.include?(type.to_sym)
    end

    def initialize(ar_column_class = nil)
      @ar_column_class = ar_column_class || ActiveRecord::ConnectionAdapters::Column
    end

    def binary(value)
      return if value.nil?
      @ar_column_class.binary_to_string(value)
    end

    def boolean(value)
      return if value.nil?
      @ar_column_class.value_to_boolean(value)
    end

    def float(value)
      return if value.nil?
      value.to_f
    end

    def date(value)
      return if value.nil?
      @ar_column_class.string_to_date(value)
    end

    def datetime(value)
      return if value.nil?
      @ar_column_class.string_to_time(value)
    end
    alias :timestamp :datetime

    def decimal(value)
      return if value.nil?
      @ar_column_class.value_to_decimal(value)
    end

    def integer(value)
      return if value.nil?
      @ar_column_class.value_to_integer(value)
    end
    alias :primary_key :integer

    def string(value)
      return if value.nil?
      value.to_s
    end
    alias :text :string

    def time(value)
      return if value.nil?
      @ar_column_class.string_to_dummy_time(value)
    end

  end

end
