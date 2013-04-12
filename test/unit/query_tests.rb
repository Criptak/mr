require 'assert'
require 'mr/query'
require 'test/support/test_models'

class MR::Query

  class BaseTests < Assert::Context
    desc "MR::Query"
    setup do
      @relation = TestFakeRecord.scoped
      @relation.results = [
        TestFakeRecord.new({ :id => 1 }),
        TestFakeRecord.new({ :id => 2 })
      ]
      @query = MR::Query.new(TestModel, @relation)
    end
    subject{ @query }

    should have_instance_methods :models, :count

    should "call count om the relation with #count" do
      assert_equal 2, subject.count
    end

    should "call `all` on the relation and build model instances with #models" do
      models = subject.models
      expected = @relation.results.map{|r| TestModel.new(r) }

      assert_equal expected, models
    end

    should "return an instance of a PagedQuery with #paged" do
      paged_query = subject.paged(1, 10)

      assert_instance_of MR::PagedQuery, paged_query
      assert_equal 1,  paged_query.page_num
      assert_equal 10, paged_query.page_size
    end

  end

  class PagedQueryTests < BaseTests
    desc "MR::PagedQuery"
    setup do
      @paged_query = MR::PagedQuery.new(@query, 1, 1)
    end
    subject{ @paged_query }

    should have_instance_methods :total_count, :total_pages, :current_page,
      :last_page?, :page_num, :page_size, :page_offset

    should "be a kind of MR::Query" do
      assert_kind_of MR::Query, subject
    end

    should "return the first page of models with #models" do
      models = subject.models
      expected = @relation.results[0, 1].map{|r| TestModel.new(r) }

      assert_equal expected, models
    end

    should "count the first page of models with #count" do
      assert_equal 1, subject.count
    end

    should "count the total number of models with #total_count" do
      assert_equal 2, subject.total_count
    end

    should "count the total number of pages with #total_pages" do
      assert_equal 2, subject.total_pages
    end

    should "return whether it's the last page or not with #last_page?" do
      assert_equal false, subject.last_page?

      paged_query = MR::PagedQuery.new(@query, 2, 1)
      assert_equal true, paged_query.last_page?
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

end
