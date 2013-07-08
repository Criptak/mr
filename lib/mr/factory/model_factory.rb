require 'mr/factory'
require 'mr/factory/record_factory'
require 'mr/stack/model_stack'

module MR; end
module MR::Factory

  class ModelFactory

    def initialize(model_class, *args)
      defaults, @fake_record_class = [
        args.last.kind_of?(Hash) ? args.pop : {},
        args.last
      ]
      @model_class    = model_class
      @defaults       = StringKeyHash.new(defaults)
      @record_factory = MR::Factory::RecordFactory.new(model_class.record_class)
      if @fake_record_class
        @fake_record_factory = MR::Factory::RecordFactory.new(@fake_record_class)
      end
    end

    def instance(fields = nil)
      record = @record_factory.instance
      @model_class.new(record, build_fields(fields))
    end

    def instance_stack(fields = nil)
      MR::Stack::ModelStack.new(@model_class).tap do |stack|
        stack.model.fields = build_fields(fields)
      end
    end

    def fake(fields = nil)
      raise "A fake_record_class wasn't provided" unless @fake_record_factory
      fake_record = @fake_record_factory.instance
      @model_class.new(fake_record, build_fields(fields))
    end

    def fake_stack(fields = nil)
      MR::Stack::ModelStack.new(@model_class, @fake_record_class).tap do |stack|
        stack.model.fields = build_fields(fields)
      end
    end

    private

    def build_fields(fields)
      fields = StringKeyHash.new(fields || {})
      @defaults.merge(fields)
    end

  end

end
