require 'mr/factory'
require 'mr/factory/apply_args'
require 'mr/factory/record_factory'
require 'mr/factory/model_stack'

module MR; end
module MR::Factory

  class ModelFactory
    include ApplyArgs

    def initialize(model_class, fake_record_class = nil, &block)
      @model_class       = model_class
      @fake_record_class = fake_record_class
      @defaults          = {}
      @instance_defaults = {}
      @fake_defaults     = {}
      self.instance_eval(&block) if block

      @record_factory = MR::Factory::RecordFactory.new(model_class.record_class)
      if @fake_record_class
        @fake_record_factory = MR::Factory::RecordFactory.new(@fake_record_class)
      end
    end

    def instance(args = nil)
      record = @record_factory.instance
      args   = @instance_defaults.merge(symbolize_hash(args))
      @model_class.new(record).tap{ |model| apply_args(model, args) }
    end

    def instance_stack(args = nil)
      MR::Factory::ModelStack.new(self.instance(args))
    end

    def fake(args = nil)
      raise "A fake_record_class wasn't provided" unless @fake_record_factory
      fake_record = @fake_record_factory.instance
      args        = @fake_defaults.merge(symbolize_hash(args))
      @model_class.new(fake_record).tap{ |model| apply_args(model, args) }
    end

    def fake_stack(args = nil)
      MR::Factory::ModelStack.new(self.fake(args))
    end

    def apply_args(model, args = nil)
      super model, @defaults.merge(symbolize_hash(args || {}))
    end

    def default_args(value = nil)
      @defaults = symbolize_hash(value) if value
      @defaults
    end

    def default_instance_args(value = nil)
      @instance_defaults = symbolize_hash(value) if value
      @instance_defaults
    end

    def default_fake_args(value = nil)
      @fake_defaults = symbolize_hash(value) if value
      @fake_defaults
    end

    private

    def apply_args_to_associations!(model, args)
      one_to_one_associations_with_args(model, args).each do |association|
        associated_model = get_associated_model(model, association)
        association_args = args.delete(association.name.to_sym)
        apply_args!(associated_model, association_args) if associated_model
      end
    end

    def get_associated_model(model, association)
      model.send(association.name) || begin
        new_model = MR::Factory.new(association.associated_class).instance
        model.send("#{association.name}=", new_model)
      end
    end

    def one_to_one_associations_with_args(model, args)
      model.class.associations.select do |association|
        hash_key?(args, association.name) && association.one_to_one?
      end
    end

  end

end
