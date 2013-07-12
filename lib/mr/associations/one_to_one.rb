require 'mr/associations/base'

module MR::Associations

  class OneToOne < MR::Associations::Base

    NullModel = Struct.new(:record)

    def one_to_one?
      true
    end

    private

    def read!(record)
      if associated_record = record.send(association_reader_name)
        self.associated_class.new(associated_record)
      end
    end

    def write!(mr_model, record)
      if mr_model && !mr_model.kind_of?(MR::Model)
        raise ArgumentError, "value must be a kind of MR::Model"
      end
      mr_model ||= NullModel.new
      record.send(association_writer_name, mr_model.send(:record))
    end

  end

  BelongsTo = Class.new(OneToOne)
  HasOne    = Class.new(OneToOne)

end
