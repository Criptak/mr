module MR; end
module MR::FakeRecord

  class Association
    attr_reader :name, :options, :ivar_name, :fake_record_class_name

    def initialize(name, options = nil)
      @name       = name
      @options    = options || {}
      @ivar_name  = "@#{name}"
      @fake_record_class_name = @options[:class_name]
    end

    def belongs_to?
      false
    end

    def collection?
      false
    end

    def reflection
      self
    end

    def fake_record_class
      @fake_record_class ||= @fake_record_class_name.constantize
    end
    alias :klass :fake_record_class

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
          association.read(self)
        end

      end
    end

    def ==(other)
      self.class == other.class && self.name == other.name
    end

    def <=>(other)
      if self.class == other.class
        self.name <=> other.name
      else
        self.class <=> other.class
      end
    end

  end

  class BelongsTo < Association
    attr_reader :foreign_key

    def initialize(name, options = nil)
      super
      @foreign_key = (@options[:foreign_key] || "#{name}_id").to_s
    end

    def belongs_to?
      true
    end

    def write(record, associated_record)
      return_value = super
      if record.respond_to?("#{@foreign_key}=")
        associated_id = associated_record ? associated_record.id : nil
        record.send("#{@foreign_key}=", associated_id)
      end
      return_value
    end

  end

  class HasMany < Association

    def collection?
      true
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

  HasOne = Class.new(Association)

end
