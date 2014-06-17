require 'assert'
require 'mr/query'

require 'ardb/relation_spy'
require 'mr/fake_record'
require 'mr/model'

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
    should have_imeths :results, :count, :count_relation

    should "call `all` on the relation and build models using #results" do
      exp = @relation.results.map{ |r| FakeTestModel.new(r) }
      assert_equal exp, subject.results
    end

    should "call `count` on the count relation using #count" do
      Assert.stub(subject, :count_relation){ @relation }
      assert_equal 2, subject.count
      Assert.stub(subject, :count_relation){ FakeTestRecord.scoped }
      assert_equal 0, subject.count
    end

    should "return an instance of a PagedQuery using #paged" do
      paged_query = subject.paged(1, 10)

      assert_instance_of MR::PagedQuery, paged_query
      assert_equal 1,  paged_query.page_num
      assert_equal 10, paged_query.page_size
    end

    should "build and cache a relation for counting from the passed relation " \
           "using #count_relation" do
      count_relation = subject.count_relation
      expected = MR::CountRelation.new(@relation)
      assert_equal expected, count_relation
      assert_same count_relation, subject.count_relation
    end

  end

  class PagedQueryTests < UnitTests
    desc "MR::PagedQuery"
    setup do
      @unpaged_relation = @relation.dup
      @paged_query = MR::PagedQuery.new(@query, 1, 1)
    end
    subject{ @paged_query }

    should have_instance_methods :total_count, :page_num, :page_size, :page_offset

    should "be a kind of MR::Query" do
      assert_kind_of MR::Query, subject
    end

    should "fetch the paged results with #results" do
      exp = @relation.results[0, 1].map{ |r| FakeTestModel.new(r) }
      assert_equal exp, subject.results
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

    should "count the paged results with #count" do
      assert_equal 1, subject.count
    end

    should "call `count` on the total count relation with #total_count" do
      Assert.stub(subject, :total_count_relation){ @unpaged_relation }
      assert_equal 2, subject.total_count
      Assert.stub(subject, :total_count_relation){ FakeTestRecord.scoped }
      assert_equal 0, subject.total_count
    end

    should "build and cache a relation for counting from the passed relation " \
           "with #total_count_relation" do
      count_relation = subject.total_count_relation
      expected = MR::CountRelation.new(@unpaged_relation)
      assert_equal expected, count_relation
      assert_same count_relation, subject.total_count_relation
    end

  end

  class CountRelationTests < UnitTests
    desc "CountRelation"
    setup do
      @relation.select('some_table.some_column')
      @relation.where('some_table.some_column = ?', 1)
      @relation.order('some_table.some_column DESC')
    end
    subject{ MR::CountRelation }

    should "return the relation with emptied select and order values when " \
           "the original relation was not grouped" do
      count_relation = subject.new(@relation)

      select_expressions = count_relation.applied.select{ |e| e.type == :select }
      assert_true select_expressions.empty?
      order_expressions = count_relation.applied.select{ |e| e.type == :order }
      assert_true order_expressions.empty?
      # still has the where expression
      where_expressions = count_relation.applied.select{ |e| e.type == :where }
      assert_equal 1, where_expressions.size
    end

    should "return a new relation for counting a subquery of the original " \
           "relation with emptied select and order values when " \
           "the original relation was grouped" do
      @relation.group_values = [ 'table.id' ]
      count_relation = subject.new(@relation)

      assert_not_equal count_relation.applied, @relation.applied
      assert_equal 1, count_relation.applied.size

      from_expression = count_relation.applied.first
      assert_equal :from, from_expression.type
      expected_relation = @relation.except(:select, :order).select(:id)
      expected = "(#{expected_relation.to_sql}) AS grouped_records"
      assert_equal [ expected ], from_expression.args
    end

  end

  class RelationSpy < Ardb::RelationSpy
    attr_reader :klass
    attr_accessor :group_values

    def initialize(klass, *args)
      super(*args)
      @klass = klass
      @group_values = []
    end

    # this is just a random readable string, it looks like:
    # select(id).where(some_id, 1)
    def to_sql
      @applied.reverse.map{ |e| "#{e.type}(#{e.args.join(", ")})" }.join('.')
    end

  end

  class FakeTestRecord
    include MR::FakeRecord

    def self.scoped
      RelationSpy.new(self)
    end
  end

  class FakeTestModel
    include MR::Model
    record_class FakeTestRecord
  end

end
