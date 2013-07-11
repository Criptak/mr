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

    def instance(args = nil)
      record = @record_factory.instance
      @model_class.new(record).tap{ |model| apply_args(model, args) }
    end

    def instance_stack(args = nil)
      MR::Stack::ModelStack.new(@model_class).tap do |stack|
        apply_args(stack.model, args)
      end
    end

    def fake(args = nil)
      raise "A fake_record_class wasn't provided" unless @fake_record_factory
      fake_record = @fake_record_factory.instance
      @model_class.new(fake_record).tap{ |model| apply_args(model, args) }
    end

    def fake_stack(args = nil)
      MR::Stack::ModelStack.new(@model_class, @fake_record_class).tap do |stack|
        apply_args(stack.model, args)
      end
    end

    private

    def apply_args(model, args)
      args = StringKeyHash.new(args || {})
      @defaults.merge(args)
      apply_args!(model, @defaults.merge(args))
    end

    def apply_args!(model, args)
      args = args.dup
      apply_args_to_associations(model, args)
      args.each{ |name, value| model.send("#{name}=", value) }
    end

    def apply_args_to_associations(model, args)
      model.class.associations.select do |association|
        one_to_one_with_args?(association, args)
      end.each do |association|
        associated_model = model.send(association.name)
        association_args = args.delete(association.name.to_s)
        apply_args!(associated_model, association_args) if associated_model
      end
    end

    def one_to_one_with_args?(association, args)
      args[association.name.to_s].kind_of?(Hash) && association.one_to_one?
    end

  end

end
