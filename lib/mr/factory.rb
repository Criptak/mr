require 'mr/factory/model_factory'
require 'mr/factory/record_factory'
require 'securerandom'

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
    SecureRandom.random_number(max) + 1
  end

  # `random_number` with no args gives a float between 0 and 1
  def self.float(max=100)
    self.integer + SecureRandom.random_number
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
      index = SecureRandom.random_number(DICTIONARY.size)
      DICTIONARY[index]
    end.join
  end

  def self.text(length=30)
    self.string(length)
  end

  def self.slug(length=10)
    parts = self.string(length).scan(/.{1,4}/)
    parts.join('-')
  end

  def self.hex(length=10)
    SecureRandom.hex(length / 2.0)
  end

  def self.boolean
    true
  end

  def self.binary
    SecureRandom.random_bytes
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
      hash.inject({}){ |h, (k, v)| h.merge(k.to_s => v) }
    end
  end

end
