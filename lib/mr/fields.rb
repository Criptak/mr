module MR; end
module MR::Fields

  module Reader
    def self.new(model_class, method_name)
      model_class.class_eval do

        define_method(method_name) do
          record.send(method_name)
        end

      end
    end
  end

  module Writer
    def self.new(model_class, method_name)
      writer_name = "#{method_name}="
      model_class.class_eval do

        define_method(writer_name) do |*args|
          record.send(writer_name, *args)
        end

      end
    end
  end

end
