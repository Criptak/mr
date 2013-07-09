require 'mr/factory/model_factory'
require 'mr/factory/record_factory'

module MR; end
module MR::Factory

  def self.new(object_class, *args)
    if object_class < MR::Model
      ModelFactory.new(object_class, *args)
    elsif object_class < MR::Record
      RecordFactory.new(object_class, *args)
    else
      raise ArgumentError, "takes a MR::Model or MR::Record"
    end
  end

  def self.primary_key(identifier = nil)
    identifier    ||= 'MR::Factory'
    @primary_keys ||= {}
    @primary_keys[identifier.to_s] ||= PrimaryKeyProvider.new
    @primary_keys[identifier.to_s].next
  end

  def self.integer(max=100)
    rand(max) + 1
  end

  # `rand` with no args gives a float between 0 and 1
  def self.float(max=100)
    self.integer(max) + rand
  end

  def self.decimal(*args)
    self.float(*args)
  end

  # allow working from a 'known' time/date/datetime, this will cache and use the
  # same value no matter when it's called, this should make for easier equality
  # checks in tests
  def self.date
    @date ||= Date.today
  end

  def self.datetime
    @datetime ||= DateTime.now
  end

  def self.time
    @time ||= Time.now
  end

  def self.timestamp
    self.time.to_i
  end

  DICTIONARY = [*'a'..'z'].freeze
  def self.string(length=10)
    [*0..(length - 1)].map do |n|
      DICTIONARY[rand(DICTIONARY.size)]
    end.join
  end

  def self.text(length=20)
    self.string(length)
  end

  def self.slug(length=10)
    parts = self.string(length).scan(/.{1,4}/)
    parts.join('-')
  end

  def self.hex(length=10)
    self.string(length).unpack('H*').first[0, length]
  end

  def self.boolean
    true
  end

  def self.binary
    [ self.integer(10000) ].pack('N*')
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

  module StringKeyHash
    def self.new(hash)
      hash.inject({}) do |h, (k, v)|
        value = v.kind_of?(Hash) ? StringKeyHash.new(v) : v
        h.merge(k.to_s => value)
      end
    end
  end

end
