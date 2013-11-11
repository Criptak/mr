require 'assert'
require 'mr/model'

module MR::Model

  class UnitTests < Assert::Context
    desc "MR::Model"
    setup do
      @model_class = Class.new do
        include MR::Model
      end
    end
    subject{ @model_class }

  end

end
