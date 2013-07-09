require 'mr/model'
require 'mr/record'
require 'mr/stack/model_stack'
require 'mr/stack/record_stack'

module MR; end
module MR::Stack

  def self.new(object_class)
    if object_class < MR::Model
      MR::Stack::ModelStack.new(object_class)
    elsif object_class < MR::Record
      MR::Stack::RecordStack.new(object_class)
    else
      raise ArgumentError, "takes a MR::Model or MR::Record"
    end
  end

end
