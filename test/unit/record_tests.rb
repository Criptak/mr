require 'assert'
require 'mr/record'

require 'test/support/models/fake_test_record'

module MR::Record

  class BaseTests < Assert::Context
    desc "MR::Record"
    setup do
      @record = FakeTestRecord.new
    end
    subject{ @record }

    should have_accessors :model

  end

end
