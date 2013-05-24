require 'mr/associations/helpers'

module MR::Associations

  class BelongsTo
    include Helpers

    NullModel = Struct.new(:record)

    def initialize(name, associated_class_name, options = nil)
      options ||= {}
      @name = name.to_s
      @associated_class_name = associated_class_name.to_s
      @record_association_name = (options[:record_association] || @name).to_s
      @associated_class = nil
      # this will be lazily set, it's used to cache the result of finding a
      # constant for the `associated_class_name`. This can't be done when the
      # `BelongsTo` is created because it will get in a circular dependency
      # loop, this is why a `BelongsTo` takes a class name, not the class
      # itself
    end

    def reader_method_name
      @name.to_s
    end

    def writer_method_name
      "#{@name}="
    end

    def association_reader_name
      @record_association_name.to_s
    end

    def association_writer_name
      "#{@record_association_name}="
    end

    def read(&record_provider)
      if !record_provider
        raise ArgumentError, 'requires a block to provide the record instance'
      end

      @associated_class ||= constantize(@associated_class_name, @name)
      record = record_provider.call
      if associated_record = record.send(association_reader_name)
        @associated_class.new(associated_record)
      end
    end

    def write(mr_model, &record_provider)
      if !record_provider
        raise ArgumentError, 'requires a block to provide the record instance'
      end
      if mr_model && !mr_model.kind_of?(MR::Model)
        raise ArgumentError, "value must be a kind of MR::Model"
      end
      mr_model ||= NullModel.new

      record = record_provider.call
      record.send(association_writer_name, mr_model.send(:record))
    end

    def define_methods(klass)
      belongs_to = self
      klass.class_eval do

        define_method(belongs_to.reader_method_name) do
          belongs_to.read{ record }
        end

        define_method(belongs_to.writer_method_name) do |mr_model|
          belongs_to.write(mr_model){ record }
          self.send(belongs_to.reader_method_name)
        end

      end
    end

  end

end