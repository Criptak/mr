module MR; end
module MR::FakeRecord

  class Association
    attr_reader :name, :fake_record_class_name
    attr_reader :ivar_name

    def initialize(name, fake_record_class_name)
      @name      = name
      @ivar_name = "@#{name}"
      @fake_record_class_name = fake_record_class_name
    end

    def type
      raise NotImplementedError
    end

    def macro
      self.type
    end

    def read(record)
      record.instance_variable_get(@ivar_name)
    end

    def write(record, value)
      record.instance_variable_set(@ivar_name, value)
    end

    def define_methods(klass)
      association = self
      klass.class_eval do

        define_method(association.name) do
          association.read(self)
        end
        define_method("#{association.name}=") do |value|
          association.write(self, value)
        end

      end
    end

    def ==(other)
      self.type == other.type && self.name == other.name
    end

    def <=>(other)
      if self.type == other.type
        self.name <=> other.name
      else
        self.type <=> other.type
      end
    end

  end

  class BelongsTo < Association
    attr_reader :foreign_key

    def initialize(name, fake_record_class_name, options = nil)
      options ||= {}
      super(name, fake_record_class_name)
      @foreign_key = (options[:foreign_key] || "#{name}_id").to_s
    end

    def type
      :belongs_to
    end

    def write(record, associated_record)
      super
      if record.respond_to?(@foreign_key)
        associated_id = associated_record ? associated_record.id : nil
        record.send("#{@foreign_key}=", associated_id)
      end
      read(record)
    end

  end

  class HasMany < Association

    def type
      :has_many
    end

    def read(record)
      if !record.instance_variable_get(@ivar_name)
        record.instance_variable_set(@ivar_name, [])
      end
      super
    end

    def write(record, value)
      super(record, [*value])
    end

  end

  class HasOne < Association

    def type
      :has_one
    end

  end

end
