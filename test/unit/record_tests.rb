require 'assert'
require 'mr/record'
require 'test/support/test_models'

module MR::Record

  class BaseTests < Assert::Context
    desc "MR::Record"
    setup do
      @record = TestFakeRecord.new
    end
    subject{ @record }

    should have_accessors :model

  end

end
