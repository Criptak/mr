require 'assert/factory'
require 'thread'
require 'mr/model'
require 'mr/model_factory'
require 'mr/read_model'
require 'mr/read_model_factory'
require 'mr/record'
require 'mr/record_factory'
require 'mr/type_converter'

module MR; end
module MR::Factory
  extend Assert::Factory

  def self.new(object_class, *args, &block)
    if object_class < MR::Model
      MR::ModelFactory.new(object_class, *args, &block)
    elsif object_class < MR::ReadModel
      MR::ReadModelFactory.new(object_class, *args, &block)
    elsif object_class < MR::Record
      MR::RecordFactory.new(object_class, *args, &block)
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

  def self.decimal(max = nil)
    self.type_cast(Assert::Factory::Random.float(max), :decimal)
  end

  def self.timestamp
    self.datetime
  end

  def self.type_converter
    @type_converter ||= MR::TypeConverter.new
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
