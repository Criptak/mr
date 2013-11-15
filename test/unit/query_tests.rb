require 'assert'
require 'mr/query'

require 'mr/fake_record'
require 'mr/model'
require 'test/support/active_record_relation_spy'

class MR::Query

  class UnitTests < Assert::Context
    desc "MR::Query"
    setup do
      @relation = FakeTestRecord.scoped
      @relation.results = [
        FakeTestRecord.new(:id => 1),
        FakeTestRecord.new(:id => 2)
      ]
      @query = MR::Query.new(FakeTestModel, @relation)
    end
    subject{ @query }

    should have_readers :model_class, :relation
    should have_imeths :models, :results, :count

    should "call count om the relation with #count" do
      assert_equal 2, subject.count
    end

    should "call `all` on the relation and build model instances with #models" do
      models = subject.models
      expected = @relation.results.map{ |r| FakeTestModel.new(r) }

      assert_equal expected, models
    end

    should "return an instance of a PagedQuery with #paged" do
      paged_query = subject.paged(1, 10)

      assert_instance_of MR::PagedQuery, paged_query
      assert_equal 1,  paged_query.page_num
      assert_equal 10, paged_query.page_size
    end

  end

  class PagedQueryTests < UnitTests
    desc "MR::PagedQuery"
    setup do
      @paged_query = MR::PagedQuery.new(@query, 1, 1)
    end
    subject{ @paged_query }

    should have_instance_methods :total_count, :page_num, :page_size, :page_offset

    should "be a kind of MR::Query" do
      assert_kind_of MR::Query, subject
    end

    should "return the first page of models with #models" do
      models = subject.models
      expected = @relation.results[0, 1].map{ |r| FakeTestModel.new(r) }

      assert_equal expected, models
    end

    should "count the first page of models with #count" do
      assert_equal 1, subject.count
    end

    should "count the total number of models with #total_count" do
      assert_equal 2, subject.total_count
    end

    should "default page number and page size" do
      paged_query = MR::PagedQuery.new(@query)

      assert_equal 1, paged_query.page_num
      assert_equal 25, paged_query.page_size
    end

    should "not allow bad page number or page size values" do
      paged_query = MR::PagedQuery.new(@query, -1, -10)

      assert_equal 1, paged_query.page_num
      assert_equal 25, paged_query.page_size

      paged_query = MR::PagedQuery.new(@query, 'a', 10.4)

      # 'a'.to_i is 0, thus it forces it to 1
      assert_equal 1,         paged_query.page_num
      # 10.4.to_i is 10, which is valid
      assert_equal 10.4.to_i, paged_query.page_size
    end

    should "correctly calculate limits and offsets" do
      paged_query = MR::PagedQuery.new(@query, 1, 10)

      assert_equal 0,  @relation.offset_value
      assert_equal 10, @relation.limit_value

      paged_query = MR::PagedQuery.new(@query, 5, 7)

      assert_equal 28, @relation.offset_value
      assert_equal 7,  @relation.limit_value
    end

  end

  class FakeTestRecord
    include MR::FakeRecord

    def self.scoped
      ActiveRecordRelationSpy.new
    end
  end

  class FakeTestModel
    include MR::Model
    record_class FakeTestRecord
  end

end
