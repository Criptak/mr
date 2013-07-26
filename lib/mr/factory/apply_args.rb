module MR; end
module MR::Factory

  module ApplyArgs

    def apply_args(object, args = nil)
      args ||= {}
      apply_args!(object, args)
    end

    private

    def apply_args!(object, args)
      args = args.dup
      apply_args_to_associations!(object, args)
      args.each do |name, value|
        proc = value.kind_of?(Proc) ? value : proc{ value }
        object.send("#{name}=", proc.call)
      end
    end

    def apply_args_to_associations!(object, args)
      raise NotImplementedError
    end

    def hash_key?(args, key)
      args[key.to_sym].kind_of?(Hash)
    end

    def deep_merge(hash1, hash2)
       hash1.merge(hash2) do |key, value1, value2|
        if value1.kind_of?(Hash) && value2.kind_of?(Hash)
          deep_merge(value1, value2)
        else
          value2
        end
      end
    end

    def symbolize_hash(hash)
      hash ||= {}
      raise ArgumentError, "must be a kind of Hash" unless hash.kind_of?(Hash)
      hash.inject({}) do |h, (k, v)|
        value = v.kind_of?(Hash) ? symbolize_hash(v) : v
        h.merge(k.to_sym => value)
      end
    end

  end

end
