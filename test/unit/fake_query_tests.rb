require 'assert'
require 'mr/fake_query'

require 'mr/fake_record'
require 'mr/model'

class MR::FakeQuery

  class UnitTests < Assert::Context
    desc "MR::FakeQuery"
    setup do
      @results = [
        FakeTestModel.new.tap{ |m| m.save },
        FakeTestModel.new.tap{ |m| m.save },
        FakeTestModel.new.tap{ |m| m.save }
      ]
      @query = MR::FakeQuery.new(@results)
    end
    subject{ @query }

    should have_imeths :results, :count, :paged

    should "return the results and their size with #results and #count" do
      assert_equal @results, subject.results
      assert_equal @results.size, subject.count
    end

    should "return an instance of a `FakePagedQuery` with #paged" do
      assert_instance_of MR::FakePagedQuery, subject.paged
    end

  end

  class FakePagedQueryTests < UnitTests
    desc "MR::FakePagedQuery"
    setup do
      @paged_query = MR::FakePagedQuery.new(@query, 1, 1)
    end
    subject{ @paged_query }

    should have_imeths :page_num, :page_size, :page_offset, :total_count

    should "be a kind of MR::FakeQuery" do
      assert_kind_of MR::FakeQuery, subject
    end

    should "fetch the paged results with #results" do
      results = subject.results
      assert_equal @results[0, 1], results
    end

    should "count the paged results with #count" do
      assert_equal 1, subject.count
    end

    should "count the total number of results with #total_count" do
      assert_equal 3, subject.total_count
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
  end

  class FakeTestModel
    include MR::Model
    record_class FakeTestRecord
  end

end
