require 'active_record'

module MR

  class TypeConverter
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

    def self.valid?(type)
      VALID_TYPES.include?(type.to_sym)
    end

    def initialize(ar_column_class = nil)
      @ar_column_class = ar_column_class || ActiveRecord::ConnectionAdapters::Column
    end

    def convert(value, type)
      return if value.nil?
      case type.to_sym
      when *TYPES[:string]   then value
      when *TYPES[:integer]  then @ar_column_class.value_to_integer(value)
      when *TYPES[:float]    then value.to_f
      when *TYPES[:decimal]  then @ar_column_class.value_to_decimal(value)
      when *TYPES[:datetime] then @ar_column_class.string_to_time(value)
      when *TYPES[:time]     then @ar_column_class.string_to_dummy_time(value)
      when *TYPES[:date]     then @ar_column_class.string_to_date(value)
      when *TYPES[:binary]   then @ar_column_class.binary_to_string(value)
      when *TYPES[:boolean]  then @ar_column_class.value_to_boolean(value)
      else
        raise ArgumentError, "#{type.inspect} is not a valid type"
      end
    end
  end

end
