require 'assert'
require 'mr/fake_query'

require 'mr/fake_record'
require 'mr/model'
require 'mr/query'

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

    should have_readers :results, :count
    should have_imeths :paged

    should "know its results and count" do
      assert_equal @results, subject.results
      assert_equal @results.size, subject.count
    end

    should "default its results and count" do
      query = MR::FakeQuery.new(nil)
      assert_equal [], query.results
      assert_equal 0, query.count
    end

    should "return an instance of a `FakePagedQuery` with #paged" do
      assert_instance_of MR::FakePagedQuery, subject.paged
    end

  end

  class FakePagedQueryTests < UnitTests
    desc "MR::FakePagedQuery"
    setup do
      @page_num = Factory.integer(@results.size)
      @page_size = 1
      @paged_query = MR::FakePagedQuery.new(@query, @page_num, @page_size)
    end
    subject{ @paged_query }

    should have_imeths :page_num, :page_size, :page_offset, :total_count

    should "be a kind of MR::FakeQuery" do
      assert_kind_of MR::FakeQuery, subject
    end

    should "know its page num/size/offset" do
      assert_equal @page_num, subject.page_num
      assert_equal @page_size, subject.page_size
      exp = MR::PagedQuery::PageOffset.new(@page_num, @page_size)
      assert_equal exp, subject.page_offset
    end

    should "know its paged results" do
      exp = @results[subject.page_offset, subject.page_size]
      assert_equal exp, subject.results
    end

    should "know its paged result count" do
      assert_equal @page_size, subject.count
    end

    should "know its total number of results " do
      assert_equal @results.size, subject.total_count
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
