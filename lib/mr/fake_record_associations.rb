require 'active_support/core_ext/string'

module MR; end
module MR::FakeRecord

  class Association
    attr_reader :name, :options, :ivar_name, :fake_record_class_name
    attr_accessor :record

    def initialize(name, options = nil)
      @name       = name
      @options    = options || {}
      @ivar_name  = "@#{name}"
      @fake_record_class_name = @options[:class_name]
    end

    def macro
      raise NotImplementedError
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

    def macro
      :belongs_to
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

    def macro
      :has_many
    end

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

  class HasOne < Association
    def macro; :has_one; end
  end

  class PolymorphicBelongsTo < BelongsTo
    attr_reader :foreign_type

    def initialize(name, options = nil)
      super
      @options[:polymorphic] = true
      @foreign_type = (@options[:foreign_type] || "#{name}_type").to_s
    end

    def fake_record_class
      if @record
        class_name = @record.send(@foreign_type)
        class_name.constantize if class_name
      else
        super
      end
    end
    alias :klass :fake_record_class

    def write(record, associated_record)
      return_value = super
      if record.respond_to?("#{@foreign_type}=")
        associated_type = associated_record ? associated_record.class.to_s : nil
        record.send("#{@foreign_type}=", associated_type)
      end
      return_value
    end

  end

end
