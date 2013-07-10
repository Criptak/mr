require 'mr/associations/base'

module MR::Associations

  class OneToMany < MR::Associations::Base

    def initialize(name, associated_class_name, options = nil)
      options ||= {}
      options[:class_name] = associated_class_name
      super(name, options)
    end

    private

    def read!(record)
      (record.send(association_reader_name) || []).map do |record|
        self.associated_class.new(record)
      end
    end

    def write!(mr_models, record)
      mr_models = [*mr_models].compact
      mr_models.each do |mr_model|
        if !mr_model.kind_of?(MR::Model)
          raise ArgumentError, "value #{mr_model.inspect} must be a kind of MR::Model"
        end
      end
      association_records = mr_models.map{|mr_model| mr_model.send(:record) }
      record.send(association_writer_name, association_records)
    end

  end

  HasMany = Class.new(OneToMany)

end
