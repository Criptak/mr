require 'mr/record_stack'

module MR

  class ModelStack

    attr_reader :model

    def initialize(model)
      @model = model
      @record_stack = MR::RecordStack.new(model.send(:record))
    end

    def create;  @record_stack.create;  end
    def destroy; @record_stack.destroy; end
    def create_dependencies;  @record_stack.create_dependencies;  end
    def destroy_dependencies; @record_stack.destroy_dependencies; end
  end

end
