require 'mr/factory'
require 'mr/factory/apply_args'
require 'mr/read_model'

module MR; end
module MR::Factory

  class ReadModelFactory
    include ApplyArgs

    def initialize(read_model_class, &block)
      raise ArgumentError, "takes a MR::ReadModel" unless read_model_class < MR::ReadModel
      @read_model_class = read_model_class
      @defaults = {}
      self.instance_eval(&block) if block
    end

    def instance(args = nil)
      data = apply_args(Data.new, args)
      @read_model_class.new(data)
    end

    def default_args(value = nil)
      raise ArgumentError, "must be a hash" if value && !value.kind_of?(Hash)
      @defaults = stringify_hash(value) if value
      @defaults
    end

    private

    def apply_args_to_associations!(object, args)
      # no-op
    end

    def apply_args(data, args = nil)
      apply_args!(data, build_defaults)
      apply_args!(data, @defaults)
      apply_args!(data, stringify_hash(args || {}))
      data
    end

    def build_defaults
      @read_model_class.fields.inject({}) do |h, field|
        h.merge(field.name.to_s => MR::Factory.send(field.type))
      end
    end

    class Data
      def initialize
        @values = {}
      end

      def [](key)
        @values[key]
      end

      def method_missing(method, *args, &block)
        method_string = method.to_s
        if method_string =~ /=\z/ && args.size == 1
          @values[method_string.gsub('=', '')] = args.first
        else
          super
        end
      end
    end

  end

end
