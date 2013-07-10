module MR; end
module MR::Record

  def self.included(receiver)
    receiver.class_eval do
      extend ClassMethods
    end
  end

  attr_writer :model

  def model
    @model ||= self.class.model_class.new(self)
  end

  module ClassMethods

    attr_accessor :model_class

  end

end
