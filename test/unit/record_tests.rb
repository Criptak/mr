require 'assert'
require 'mr/record'

require 'test/support/models/fake_test_record'
require 'test/support/models/test_model'

module MR::Record

  class BaseTests < Assert::Context
    desc "MR::Record"
    setup do
      @record = FakeTestRecord.new
    end
    subject{ @record }

    should have_accessors :model
    should have_cmeths :model_class, :model_class=

    should "build a model if one hasn't been set" do
      assert_instance_of TestModel, subject.model
    end

  end

end
