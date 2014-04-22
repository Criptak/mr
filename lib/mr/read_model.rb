require 'mr/read_model/data'
require 'mr/read_model/fields'
require 'mr/read_model/querying'

module MR; end
module MR::ReadModel

  def self.included(klass)
    klass.class_eval do
      include MR::ReadModel::Data
      include MR::ReadModel::Fields
      include MR::ReadModel::Querying
    end
  end

  def initialize(data = nil)
    set_read_model_data(data || {})
  end

  def ==(other)
    if other.kind_of?(self.class)
      self.fields == other.fields
    else
      super
    end
  end

  def inspect
    object_hex = (self.object_id << 1).to_s(16)
    fields_inspect = self.class.fields.map do |field|
      "#{field.ivar_name}=#{field.read(self.read_model_data).inspect}"
    end.sort.join(" ")
    "#<#{self.class}:0x#{object_hex} #{fields_inspect}>"
  end

end
