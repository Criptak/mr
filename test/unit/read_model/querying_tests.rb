require 'assert'
require 'mr/read_model/querying'

require 'mr/fake_record'

module MR::ReadModel::Querying

  class UnitTests < Assert::Context
    desc "MR::ReadModel::Querying"
    setup do
      @read_model_class = Class.new do
        include MR::ReadModel::Querying
      end
    end
    subject{ @read_model_class }

    should have_imeths :relation
    should have_imeths :query
    should have_imeths :select
    should have_imeths :from, :joins
    should have_imeths :where
    should have_imeths :order
    should have_imeths :group, :having
    should have_imeths :limit, :offset
    should have_imeths :merge

    should "return a Relation using `relation`" do
      relation = subject.relation
      assert_instance_of MR::ReadModel::Relation, relation
      assert_same relation, subject.relation
    end

    should "set the relation's record class using `from`" do
      subject.from TestRecord
      assert_equal TestRecord, subject.relation.record_class
    end

    should "raise an ArgumentError when passing `from` a non MR::Record" do
      assert_raises(ArgumentError){ subject.from(Class.new) }
    end

    should "raise a no record class error when using the relation before it's configured" do
      assert_raises(MR::ReadModel::NoRecordClassError){ subject.query }
    end

    private

    def assert_static_expression_added(relation, type, *args)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions.size
        expression = relation.expressions.first
        expected_class = MR::ReadModel::QueryExpression::Static
        assert_instance_of expected_class, expression
        assert_equal type, expression.type
        assert_equal args, expression.args
      end
    end

    def assert_dynamic_expression_added(relation, type, block)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions.size
        expression = relation.expressions.first
        expected_class = MR::ReadModel::QueryExpression::Dynamic
        assert_instance_of expected_class, expression
        assert_equal type,  expression.type
        assert_equal block, expression.block
      end
    end

    def assert_expression_applied(relation_spy, type, *args)
      with_backtrace(caller) do
        applied = relation_spy.applied.detect do |e|
          e.type == type && e.args == args
        end
        assert applied
      end
    end

  end

  class WithFromRecordClassTests < UnitTests
    setup do
      @ar_relation_spy = ActiveRecordRelationSpy.new
      TestRecord.stubs(:scoped).returns(@ar_relation_spy)
      @read_model_class.from TestRecord
      @relation = @read_model_class.relation
    end
    teardown do
      TestRecord.unstub(:scoped)
    end

    should "apply a static select to the relation with `select`" do
      select_sql = "some_table.some_column AS 'something'"
      subject.select select_sql
      assert_static_expression_added @relation, :select, select_sql
    end

    should "add a dynamic select to the relation with `select`" do
      select_proc = proc{ |name| "some_table.some_column AS '#{name}'" }
      subject.select(&select_proc)
      assert_dynamic_expression_added @relation, :select, select_proc
    end

    should "add a static join to the relation with `joins`" do
      join_args = [ :some_table, :other_table ]
      subject.joins(*join_args)
      assert_static_expression_added @relation, :joins, *join_args
    end

    should "add a dynamic join to the relation with `joins`" do
      join_proc = proc{ |name| "CROSS JOIN #{name}" }
      subject.joins(&join_proc)
      assert_dynamic_expression_added @relation, :joins, join_proc
    end

    should "add a static where to the relation with `where`" do
      where_args = { :column => 'value' }
      subject.where(where_args)
      assert_static_expression_added @relation, :where, where_args
    end

    should "add a dynamic where to the relation with `where`" do
      where_proc = proc{ |name| { :column => name } }
      subject.where(&where_proc)
      assert_dynamic_expression_added @relation, :where, where_proc
    end

    should "add a static order to the relation with `order`" do
      order_args = 'some_table.some_column'
      subject.order(order_args)
      assert_static_expression_added @relation, :order, order_args
    end

    should "add a dynamic order to the relation with `order`" do
      order_proc = proc{ |column| column }
      subject.order(&order_proc)
      assert_dynamic_expression_added @relation, :order, order_proc
    end

    should "add a static group to the relation with `group`" do
      group_args = 'some_table.some_column'
      subject.group(group_args)
      assert_static_expression_added @relation, :group, group_args
    end

    should "add a dynamic group to the relation with `group`" do
      group_proc = proc{ |column| column }
      subject.group(&group_proc)
      assert_dynamic_expression_added @relation, :group, group_proc
    end

    should "add a static having to the relation with `having`" do
      having_args = 'COUNT(*) > 0'
      subject.having(having_args)
      assert_static_expression_added @relation, :having, having_args
    end

    should "add a dynamic having to the relation with `having`" do
      having_proc = proc{ |column| "COUNT(#{column}) > 0" }
      subject.having(&having_proc)
      assert_dynamic_expression_added @relation, :having, having_proc
    end

    should "add a static limit to the relation with `limit`" do
      limit_args = 1
      subject.limit(limit_args)
      assert_static_expression_added @relation, :limit, limit_args
    end

    should "add a dynamic limit to the relation with `limit`" do
      limit_proc = proc{ |count| count }
      subject.limit(&limit_proc)
      assert_dynamic_expression_added @relation, :limit, limit_proc
    end

    should "add a static offset to the relation with `offset`" do
      offset_args = 1
      subject.offset(offset_args)
      assert_static_expression_added @relation, :offset, offset_args
    end

    should "add a dynamic offset to the relation with `offset`" do
      offset_proc = proc{ |count| count }
      subject.offset(&offset_proc)
      assert_dynamic_expression_added @relation, :offset, offset_proc
    end

    should "add a static merge to the relation with `merge`" do
      merge_args = 'fake-relation'
      subject.merge(merge_args)
      assert_static_expression_added @relation, :merge, merge_args
    end

    should "add a dynamic merge to the relation with `merge`" do
      merge_proc = proc{ 'fake-relation' }
      subject.merge(&merge_proc)
      assert_dynamic_expression_added @relation, :merge, merge_proc
    end

    should "raise an ArgumentError when any query method isn't provided args or a block" do
      assert_raises(ArgumentError){ subject.select }
      assert_raises(ArgumentError){ subject.joins }
      assert_raises(ArgumentError){ subject.where }
      assert_raises(ArgumentError){ subject.order }
      assert_raises(ArgumentError){ subject.group }
      assert_raises(ArgumentError){ subject.having }
      assert_raises(ArgumentError){ subject.limit }
      assert_raises(ArgumentError){ subject.offset }
      assert_raises(ArgumentError){ subject.merge }
    end

  end

  class QueryTests < WithFromRecordClassTests
    desc "query"
    setup do
      @read_model_class.select(:name)
      @query = @read_model_class.query
    end
    subject{ @query }

    should "return an instance of an MR::Query for the class and relation" do
      assert_instance_of MR::Query, subject
      assert_equal @read_model_class, subject.model_class
      assert_equal @ar_relation_spy,  subject.relation
    end

    should "have applied the query expressions to the relation" do
      assert_expression_applied @ar_relation_spy, :select, :name
    end

  end

  class RelationTests < UnitTests
    desc "Relation"
    setup do
      @relation = MR::ReadModel::Relation.new
      @relation.record_class = TestRecord
    end
    subject{ @relation }

    should have_accessors :record_class
    should have_readers :expressions

    should "default it's record class and query expressions" do
      relation = MR::ReadModel::Relation.new
      assert_nil relation.record_class
      assert_equal [], relation.expressions
    end

    should "return an ActiveRecord relation from the record class using `build`" do
      assert_equal TestRecord.scoped, subject.build
    end

    should "return a new relation everytime `build` is called" do
      ar_relation = subject.build
      assert_not_same ar_relation, subject.build
    end

    should "apply query expressions in the order they are added using `build`" do
      subject.expressions << MR::ReadModel::QueryExpression.new(:order, :first_column)
      subject.expressions << MR::ReadModel::QueryExpression.new(:where, :second_column)
      subject.expressions << MR::ReadModel::QueryExpression.new(:joins, :third_column)
      ar_relation = subject.build

      expected_order = subject.expressions.map{ |e| [ e.type, e.args ] }
      actual_order   = ar_relation.applied.map{ |e| [ e.type, e.args ] }
      assert_equal expected_order, actual_order
    end

    should "apply query expressions using the args passed to `build`" do
      subject.expressions << MR::ReadModel::QueryExpression.new(:select){ |c| c }
      ar_relation = subject.build('some_table.some_column')
      assert_expression_applied ar_relation, :select, 'some_table.some_column'
    end

    should "raise a no record class error using `build` with no record class" do
      subject.record_class = nil
      assert_raises(MR::ReadModel::NoRecordClassError){ subject.build }
    end

  end

  class TestRecord
    include MR::FakeRecord

    def self.scoped
      ActiveRecordRelationSpy.new
    end

  end

  class ActiveRecordRelationSpy
    attr_reader :applied

    def initialize
      @applied = []
    end

    [ :select,
      :joins,
      :where,
      :order,
      :group, :having,
      :limit, :offset,
      :merge
    ].each do |type|

      define_method(type) do |*args|
        @applied << AppliedExpression.new(type, args)
        self
      end

    end

    def ==(other)
      @applied == other.applied
    end

    AppliedExpression = Struct.new(:type, :args)

  end

end
