require 'mr/factory'
require 'mr/factory/apply_args'
require 'mr/factory/record_factory'
require 'mr/factory/model_stack'

module MR; end
module MR::Factory

  class ModelFactory
    include ApplyArgs

    def initialize(model_class, record_class, &block)
      @model_class  = model_class
      @record_class = record_class
      @defaults     = {}
      self.instance_eval(&block) if block

      @record_factory = MR::Factory::RecordFactory.new(@record_class)
    end

    def instance(args = nil)
      record = @record_factory.instance
      @model_class.new(record).tap{ |model| apply_args(model, args) }
    end

    def instance_stack(args = nil)
      MR::Factory::ModelStack.new(self.instance(args))
    end

    def apply_args(model, args = nil)
      super model, deep_merge(@defaults, stringify_hash(args || {}))
    end

    def default_args(value = nil)
      @defaults = stringify_hash(value) if value
      @defaults
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
        new_model = ModelFactory.new(
          associated_model_class,
          associated_record_class
        ).instance
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
