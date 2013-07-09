require 'mr/factory'
require 'mr/factory/record_factory'

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

    def instance(attrs = nil)
      attrs = StringKeyHash.new(attrs || {})
      record = @record_factory.instance
      @model_class.new(record, @defaults.merge(attrs))
    end

    def fake(attrs = nil)
      attrs = StringKeyHash.new(attrs || {})
      raise "A fake_record_class wasn't provided" unless @fake_record_factory
      fake_record = @fake_record_factory.instance
      @model_class.new(fake_record, @defaults.merge(attrs))
    end

  end

end
