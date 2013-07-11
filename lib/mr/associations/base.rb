require 'active_support/core_ext/string'

module MR::Associations

  class Base
    attr_reader :name

    def initialize(name, options = nil)
      options ||= {}
      @name = name.to_s
      @associated_class_name   = options[:class_name]
      @record_association_name = (options[:record_association] || @name).to_s
      @associated_class = nil
      # this will be lazily set, it's used to cache the result of finding a
      # constant for the `associated_class_name`. This can't be done when the
      # association class is created because it will get in a circular
      # dependency loop, this is why the associations take a class name, not the
      # class itself
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

    def one_to_one?
      false
    end

    def one_to_many?
      false
    end

    def associated_class
      return if !@associated_class_name
      @associated_class ||= constantize(@associated_class_name, @name)
    end

    def read(&record_provider)
      if !record_provider
        raise ArgumentError, 'requires a block to provide the record instance'
      end
      read!(record_provider.call)
    end

    def write(value, &record_provider)
      if !record_provider
        raise ArgumentError, 'requires a block to provide the record instance'
      end
      write!(value, record_provider.call)
    end

    def define_methods(klass)
      association = self
      klass.class_eval do

        define_method(association.reader_method_name) do
          association.read{ record }
        end

        define_method(association.writer_method_name) do |value|
          association.write(value){ record }
          self.send(association.reader_method_name)
        end

      end
    end

    private

    def read!(record)
      raise NotImplementedError
    end

    def write!(value, record)
      raise NotImplementedError
    end

    def constantize(class_name, name)
      class_name.to_s.constantize
    rescue NameError
      raise NoAssociatedClassError.new(name, class_name)
    end

  end

  class NoAssociatedClassError < RuntimeError
    def initialize(name, class_name)
      super "A class couldn't be found " \
            "for the #{name.inspect} association using #{class_name.inspect}"
    end
  end

end
