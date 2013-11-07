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
      args   = deep_merge(@instance_defaults, stringify_hash(args))
      @model_class.new(record).tap{ |model| apply_args(model, args) }
    end

    def instance_stack(args = nil)
      MR::Factory::ModelStack.new(self.instance(args))
    end

    def fake(args = nil)
      raise "A fake_record_class wasn't provided" unless @fake_record_factory
      fake_record = @fake_record_factory.instance
      args        = deep_merge(@fake_defaults, stringify_hash(args))
      @model_class.new(fake_record).tap{ |model| apply_args(model, args) }
    end

    def fake_stack(args = nil)
      MR::Factory::ModelStack.new(self.fake(args))
    end

    def apply_args(model, args = nil)
      super model, deep_merge(@defaults, stringify_hash(args || {}))
    end

    def default_args(value = nil)
      @defaults = stringify_hash(value) if value
      @defaults
    end

    def default_instance_args(value = nil)
      @instance_defaults = stringify_hash(value) if value
      @instance_defaults
    end

    def default_fake_args(value = nil)
      @fake_defaults = stringify_hash(value) if value
      @fake_defaults
    end

    private

    def apply_args_to_associations!(model, args)
      one_to_one_associations_with_args(model, args).each do |association|
        associated_model = get_associated_model(model, association)
        association_args = args.delete(association.name.to_s)
        apply_args!(associated_model, association_args) if associated_model
      end
    end

    def get_associated_model(model, association)
      model.send(association.reader_method_name) || begin
        # TODO - don't do this, should pass it in
        record = model.send(:record)
        ar_association = record.association(association.name)
        associated_record_class = ar_association.klass ||
                                  NullRecordClass.new(association.name)
        associated_model_class  = associated_record_class.model_class
        new_model = MR::Factory.new(associated_model_class).instance
        model.send("#{association.name}=", new_model)
      end
    end

    def one_to_one_associations_with_args(model, args)
      (model.class.associations.belongs_to +
       model.class.associations.polymorphic_belongs_to +
       model.class.associations.has_one).select{ |a| hash_key?(args, a.name) }
    end

    class NullRecordClass
      def initialize(association_name)
        @association_name = association_name
      end

      # TODO - throw a better exception, get more info from AR association and
      # throw custom error for polymorphic cases
      def model_class
        raise NoRecordClassError, "an associated record class couldn't be " \
                                  "determined for '#{@association_name}'"
      end
    end

    NoRecordClassError = Class.new(RuntimeError)

  end


end
