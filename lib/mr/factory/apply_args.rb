module MR; end
module MR::Factory

  module ApplyArgs

    def apply_args(object, args = nil)
      args ||= {}
      apply_args!(object, args.dup)
    end

    private

    def apply_args!(object, args)
      apply_args_to_associations!(object, args)
      args.each{ |name, value| object.send("#{name}=", value) }
    end

    def apply_args_to_associations!(object, args)
      raise NotImplementedError
    end

    def hash_key?(args, key)
      args[key.to_sym].kind_of?(Hash)
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