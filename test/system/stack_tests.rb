require 'assert'
require 'mr/stack'

require 'test/support/setup_test_db'
require 'test/support/models/comment'
require 'test/support/models/comment_record'

module MR::Stack

  class BaseTests < Assert::Context
    desc "MR::Stack"
    subject{ MR::Stack }

    should have_imeths :new

    should "return a MR::Stack::RecordStack class with #new given an MR::Record" do
      factory = subject.new(CommentRecord)
      assert_instance_of MR::Stack::RecordStack, factory
    end

    should "return a MR::Stack::ModelStack class with #new given an MR::Model" do
      factory = subject.new(Comment)
      assert_instance_of MR::Stack::ModelStack, factory
    end

    should "raise an ArgumentError when not give a MR::Model or MR::Record" do
      assert_raises(ArgumentError) do
        subject.new('test')
      end
    end

  end

end
