require 'assert'
require 'mr/record'

module MR::Record

  class UnitTests < Assert::Context
    desc "MR::Record"
    setup do
      @record_class = Class.new do
        include MR::Record
        self.model_class = FakeTestModel
      end
    end
    subject{ @record_class }

    should have_accessors :model_class

  end

  class InstanceTests < UnitTests
    desc "instance"
    setup do
      @record = @record_class.new
    end
    subject{ @record }

    should have_accessors :model

    should "build a model if one hasn't been set" do
      assert_instance_of FakeTestModel, subject.model
    end

  end

  class FakeTestModel
    include MR::Model
  end

end
