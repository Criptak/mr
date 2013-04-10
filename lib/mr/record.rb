module MR; end
module MR::Record

  def self.included(receiver)
    receiver.class_eval do

      attr_accessor :model

    end
  end

end
