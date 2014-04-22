require 'assert'
require 'mr/read_model/data'

module MR::ReadModel::Data

  class UnitTests < Assert::Context
    desc "MR::ReadModel::Data"
    setup do
      @read_model_class = Class.new do
        include MR::ReadModel::Data
      end
    end
    subject{ @read_model_class }

  end

  class InstanceTests < UnitTests

    # These private methods are tested because they are an interace to the other
    # mixins.

    desc "for a read model instance"
    setup do
      @read_model_class.class_eval do

        def read_data
          self.read_model_data
        end

        def write_data(data)
          set_read_model_data(data)
        end

      end
      @data = {}
      @read_model = @read_model_class.new
    end
    subject{ @read_model }

    should "allow reading the `data` through the protected method" do
      subject.write_data(@data)
      assert_equal @data, subject.read_data
    end

    should "raise a no record error if a record hasn't been set" do
      assert_raises(MR::ReadModel::NoDataError){ subject.read_data }
    end

    should "raise an invalid data error when setting data that doesn't " \
           "respond to the index (`[]`) method" do
      assert_raises(MR::ReadModel::InvalidDataError){ subject.write_data(true) }
    end

  end

end
