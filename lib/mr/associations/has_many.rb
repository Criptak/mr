require 'mr/associations/helpers'

module MR::Associations

  class HasMany
    include Helpers

    def initialize(name, associated_class_name, options = nil)
      options ||= {}
      @name = name.to_s
      @associated_class_name = associated_class_name.to_s
      @record_association_name = (options[:record_association] || @name).to_s
      @associated_class = nil
      # this will be lazily set, it's used to cache the result of finding a
      # constant for the `associated_class_name`. This can't be done when the
      # `HasMany` is created because it will get in a circular dependency
      # loop, this is why a `HasMany` takes a class name, not the class
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
      (record.send(association_reader_name) || []).map do |record|
        @associated_class.new(record)
      end
    end

    def write(mr_models, &record_provider)
      mr_models = [*mr_models].compact
      if !record_provider
        raise ArgumentError, 'requires a block to provide the record instance'
      end
      mr_models.each do |mr_model|
        if !mr_model.kind_of?(MR::Model)
          raise ArgumentError, "value #{mr_model.inspect} must be a kind of MR::Model"
        end
      end

      record = record_provider.call
      association_records = mr_models.map{|mr_model| mr_model.send(:record) }
      record.send(association_writer_name, association_records)
    end

    def define_methods(klass)
      has_many = self
      klass.class_eval do

        define_method(has_many.reader_method_name) do
          has_many.read{ record }
        end

        define_method(has_many.writer_method_name) do |mr_models|
          has_many.write(mr_models){ record }
          self.send(has_many.reader_method_name)
        end

      end
    end

  end

end
