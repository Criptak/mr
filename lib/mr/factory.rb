require 'mr/factory/model_factory'
require 'mr/factory/read_model_factory'
require 'mr/factory/record_factory'
require 'mr/type_converter'

module MR; end
module MR::Factory

  def self.new(object_class, *args, &block)
    if object_class < MR::Model
      ModelFactory.new(object_class, *args, &block)
    elsif object_class < MR::ReadModel
      ReadModelFactory.new(object_class, *args, &block)
    elsif object_class < MR::Record
      RecordFactory.new(object_class, *args, &block)
    else
      raise ArgumentError, "takes a MR::Model, MR::Record, or MR::ReadModel"
    end
  end

  def self.primary_key(identifier = nil)
    identifier    ||= 'MR::Factory'
    @primary_keys ||= {}
    @primary_keys[identifier.to_s] ||= PrimaryKeyProvider.new
    self.type_cast(@primary_keys[identifier.to_s].next, :primary_key)
  end

  def self.integer(max = nil)
    self.type_cast(Random.integer(max), :integer)
  end

  def self.float(max = nil)
    self.type_cast(Random.float(max), :float)
  end

  def self.decimal(max = nil)
    self.type_cast(Random.float(max), :decimal)
  end

  # allow working from a 'known' time/date/datetime/timestamp, this will cache
  # and use the same value no matter when it's called, this should make for
  # easier equality checks in tests
  def self.date
    @date ||= self.type_cast(Random.date_string, :date)
  end

  def self.time
    @time ||= self.type_cast(Random.time_string, :time)
  end

  def self.datetime
    @datetime ||= self.type_cast(Random.datetime_string, :datetime)
  end

  def self.timestamp
    @timestamp ||= self.type_cast(Random.datetime_string, :timestamp)
  end

  def self.string(length = nil)
    self.type_cast(Random.string(length), :string)
  end

  def self.text(length = nil)
    self.type_cast(Random.string(length || 20), :text)
  end

  def self.slug(length = nil)
    self.type_cast(Random.slug_string(length), :string)
  end

  def self.hex(length = nil)
    self.type_cast(Random.hex_string(length), :string)
  end

  def self.binary
    self.type_cast(Random.binary, :binary)
  end

  def self.boolean
    self.type_cast(Random.integer.even?, :boolean)
  end

  def self.type_cast(value, type)
    self.type_converter.convert(value, type)
  end

  def self.type_converter
    @type_converter ||= MR::TypeConverter.new
  end

  module Random
    def self.integer(max = nil)
      rand(max || 100) + 1
    end

    # `rand` with no args gives a float between 0 and 1
    def self.float(max = nil)
      (self.integer((max || 100) - 1) + rand).to_f
    end

    def self.date_string
      Time.now.strftime("%Y-%m-%d")
    end

    def self.datetime_string
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end

    def self.time_string
      Time.now.strftime("%H:%M:%S")
    end

    DICTIONARY = [*'a'..'z'].freeze
    def self.string(length = nil)
      [*0..((length || 10) - 1)].map{ |n| DICTIONARY[rand(DICTIONARY.size)] }.join
    end

    def self.slug_string(length = nil)
      self.string(length).scan(/.{1,4}/).join('-')
    end

    def self.hex_string(length = nil)
      length ||= 10
      self.integer(("f" * length).hex - 1).to_s(16).rjust(length, '0')
    end

    def self.binary
      [ self.integer(10000) ].pack('N*')
    end
  end

  class PrimaryKeyProvider
    attr_reader :mutex, :current
    def initialize
      @current = 0
      @mutex   = Mutex.new
    end
    def next
      @mutex.synchronize{ @current += 1 }
    end
  end

end
