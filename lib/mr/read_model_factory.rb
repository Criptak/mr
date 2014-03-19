require 'mr/factory'
require 'mr/factory/apply_args'
require 'mr/read_model'

module MR

  class ReadModelFactory
    include MR::Factory::ApplyArgs

    def initialize(read_model_class, &block)
      raise ArgumentError, "takes a MR::ReadModel" unless read_model_class < MR::ReadModel
      @read_model_class = read_model_class
      @defaults = {}
      self.instance_eval(&block) if block
    end

    def instance(args = nil)
      data = deep_merge(build_defaults, stringify_hash(args || {}))
      @read_model_class.new(data)
    end

    def default_args(value = nil)
      raise ArgumentError, "must be a hash" if value && !value.kind_of?(Hash)
      @defaults = stringify_hash(value) if value
      @defaults
    end

    private

    def build_defaults
      @read_model_class.fields.inject({}) do |h, field|
        h.merge(field.name.to_s => MR::Factory.send(field.type))
      end
    end

  end

end
