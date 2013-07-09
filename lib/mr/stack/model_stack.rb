require 'mr/stack/record_stack'

module MR; end
module MR::Stack

  class ModelStack

    attr_reader :model

    def initialize(model_class, record_class = nil)
      record_class ||= model_class.record_class
      @record_stack = MR::Stack::RecordStack.new(record_class)
      @model = model_class.new(@record_stack.record)
    end

    def create;  @record_stack.create;  end
    def destroy; @record_stack.destroy; end
    def create_dependencies;  @record_stack.create_dependencies;  end
    def destroy_dependencies; @record_stack.destroy_dependencies; end
  end

end
