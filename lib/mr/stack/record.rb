require 'mr/factory'

module MR; end
module MR::Stack

  class Record

    attr_reader :instance, :associations

    def initialize(record_class)
      @record_class = record_class
      @associations = belongs_to_associations(@record_class)
      @instance = MR::Factory.new(@record_class).instance
    end

    def set_association(name, stack_record)
      @instance.send("#{name}=", stack_record.instance)
    end

    def create
      @instance.save!
    end

    def destroy
      @instance.destroy
    end

    private

    def belongs_to_associations(record_class)
      record_class.reflect_on_all_associations.map do |reflection|
        next if reflection.macro != :belongs_to
        Association.new(reflection.klass, reflection.name)
      end.compact
    end

    class Association < Struct.new(:record_class, :name)
      def key
        record_class.to_s
      end
    end

  end

end
