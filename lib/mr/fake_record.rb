require 'mr/fake_record/associations'
require 'mr/fake_record/attributes'
require 'mr/fake_record/persistence'
require 'mr/record'

module MR; end
module MR::FakeRecord

  def self.included(klass)
    klass.class_eval do
      include MR::Record
      include MR::FakeRecord::Associations
      include MR::FakeRecord::Attributes
      include MR::FakeRecord::Persistence
      extend ClassMethods
    end
  end

  def initialize(attrs = nil)
    self.attributes = attrs || {}
  end

  def ==(other)
    other.kind_of?(self.class) ? self.id == other.id : super
  end

  def inspect
    object_hex = (self.object_id << 1).to_s(16)
    attributes_inspect = self.class.attributes.map do |attribute|
      "@#{attribute.name}=#{attribute.read(self).inspect}"
    end.sort.join(" ")
    "#<#{self.class}:0x#{object_hex} #{attributes_inspect}>"
  end

  module ClassMethods

    def model_class(value = nil)
      @model_class = value if value
      @model_class
    end

  end

end
