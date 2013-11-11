require 'mr/model/associations'
require 'mr/model/configuration'
require 'mr/model/fields'
require 'mr/model/persistence'

module MR; end
module MR::Model

  def self.included(klass)
    klass.class_eval do
      include MR::Model::Configuration
      include MR::Model::Fields
      include MR::Model::Associations
      include MR::Model::Persistence
      extend ClassMethods
    end
  end

  def initialize(*args)
    field_values = args.pop if args.last.kind_of?(Hash)
    set_record(args.first || self.record_class.new)
    (field_values || {}).each do |name, value|
      self.send("#{name}=", value)
    end
  end

  def ==(other)
    other.kind_of?(self.class) ? record == other.record : super
  end

  def inspect
    object_hex = (self.object_id << 1).to_s(16)
    fields_inspect = self.class.fields.map do |field|
      "@#{field.name}=#{field.read(record).inspect}"
    end.sort.join(" ")
    "#<#{self.class}:0x#{object_hex} #{fields_inspect}>"
  end

  module ClassMethods

    def find(id)
      self.new(self.record_class.find(id))
    end

    def all
      self.record_class.all.map{ |record| self.new(record) }
    end

  end

end
