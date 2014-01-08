require 'assert'
require 'mr/read_model/querying'

require 'ardb/relation_spy'
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
    should have_imeths :find, :query
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
      subject.from FakeTestRecord
      assert_equal FakeTestRecord, subject.relation.record_class
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
        assert_equal 1, relation.expressions[type].size
        expression = relation.expressions[type].first
        assert_static_expression expression, type, args
      end
    end

    def assert_dynamic_expression_added(relation, type, block)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions[type].size
        expression = relation.expressions[type].first
        assert_dynamic_expression expression, type, block
      end
    end

    def assert_static_merge_expression_added(relation, type, *args)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions[type].size
        merge_expression = relation.expressions[type].first
        expected_class = MR::ReadModel::MergeQueryExpression
        assert_instance_of expected_class, merge_expression
        assert_static_expression merge_expression.query_expression, :merge, args
      end
    end

    def assert_dynamic_merge_expression_added(relation, type, block)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions[type].size
        merge_expression = relation.expressions[type].first
        expected_class = MR::ReadModel::MergeQueryExpression
        assert_instance_of expected_class, merge_expression
        assert_dynamic_expression merge_expression.query_expression, :merge, block
      end
    end

    def assert_static_expression(expression, type, args)
      expected_class = MR::ReadModel::QueryExpression::Static
      assert_instance_of expected_class, expression
      assert_equal type, expression.type
      assert_equal args, expression.args
    end

    def assert_dynamic_expression(expression, type, block)
      expected_class = MR::ReadModel::QueryExpression::Dynamic
      assert_instance_of expected_class, expression
      assert_equal type,  expression.type
      assert_equal block, expression.block
    end

    def assert_expression_applied(relation_spy, type, *args)
      with_backtrace(caller) do
        assert_not_nil find_applied(relation_spy, type, args)
      end
    end

    def assert_not_expression_applied(relation_spy, type, *args)
      with_backtrace(caller) do
        assert_nil find_applied(relation_spy, type, args)
      end
    end

    def find_applied(relation_spy, type, args)
      relation_spy.applied.detect{ |e| e.type == type && e.args == args }
    end

  end

  class WithFromRecordClassTests < UnitTests
    setup do
      @ar_relation_spy = Ardb::RelationSpy.new
      FakeTestRecord.stubs(:scoped).returns(@ar_relation_spy)
      @read_model_class.from FakeTestRecord
      @relation = @read_model_class.relation
    end
    teardown do
      FakeTestRecord.unstub(:scoped)
    end

    should "add a static select to the relation with `select`" do
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

    should "add a static merge to the relation with `where`" do
      merge_args = 'fake-relation'
      subject.where(merge_args)
      assert_static_merge_expression_added @relation, :where, merge_args
    end

    should "add a dynamic merge to the relation with `where`" do
      merge_proc = proc{ 'fake-relation' }
      subject.where(&merge_proc)
      assert_dynamic_merge_expression_added @relation, :where, merge_proc
    end

    should "add a static merge to the relation with `order`" do
      merge_args = 'fake-relation'
      subject.order(merge_args)
      assert_static_merge_expression_added @relation, :order, merge_args
    end

    should "add a dynamic merge to the relation with `order`" do
      merge_proc = proc{ 'fake-relation' }
      subject.order(&merge_proc)
      assert_dynamic_merge_expression_added @relation, :order, merge_proc
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
      assert_static_merge_expression_added @relation, :merge, merge_args
    end

    should "add a dynamic merge to the relation with `merge`" do
      merge_proc = proc{ 'fake-relation' }
      subject.merge(&merge_proc)
      assert_dynamic_merge_expression_added @relation, :merge, merge_proc
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

  class FindTests < WithFromRecordClassTests
    desc "find"
    setup do
      @read_model_class.class_eval do
        attr_accessor :id
        select :id
        limit 1
        def initialize(data)
          data.each{ |k, v| send("#{k}=", v) }
        end
      end
      @read_model = @read_model_class.new(:id => 1)
      @ar_relation_spy.results = [ @read_model ]
      @result = @read_model_class.find(@read_model.id)
    end
    subject{ @result }

    should "return the matching read model" do
      assert_equal @read_model.id, subject.id
    end

    should "have only applied a subset of the query expressions to the relation" do
      assert_expression_applied @ar_relation_spy, :select, :id
      assert_not_expression_applied @ar_relation_spy, :limit, 1
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
      @relation.record_class = FakeTestRecord
    end
    subject{ @relation }

    should have_accessors :record_class
    should have_readers :expressions
    should have_imeths :add_expression
    should have_imeths :build_for_all, :build_for_find

    should "default it's record class and query expressions" do
      relation = MR::ReadModel::Relation.new
      assert_nil relation.record_class
      assert_equal({}, relation.expressions)
    end

    should "add an expression to it's expressions using `add_expression`" do
      expression = MR::ReadModel::QueryExpression.new(:select, 'first_column')
      subject.add_expression expression
    end

    should "return a relation from the record class using `build_for_find`" do
      assert_equal FakeTestRecord.scoped, subject.build_for_find
    end

    should "return a new relation everytime `build_for_find` is called" do
      ar_relation = subject.build_for_find
      assert_not_same ar_relation, subject.build_for_find
    end

    should "apply query expressions of the same type " \
           "in the order they are added using `build_for_find`" do
      [ :first_column, :second_column, :third_column ].each do |column|
        subject.add_expression MR::ReadModel::QueryExpression.new(:joins, column)
      end
      ar_relation = subject.build_for_find
      expected_order = subject.expressions[:joins].map{ |e| [ e.type, e.args ] }
      actual_order   = ar_relation.applied.map{ |e| [ e.type, e.args ] }
      assert_equal expected_order, actual_order
    end

    should "apply query expressions using the args passed to `build_for_find`" do
      subject.add_expression MR::ReadModel::QueryExpression.new(:select){ |c| c }
      ar_relation = subject.build_for_find('some_table.some_column')
      assert_expression_applied ar_relation, :select, 'some_table.some_column'
    end

    should "not apply where, order, limit or offset expressions using `build_for_find`" do
      expression_class = MR::ReadModel::MergeQueryExpression
      subject.add_expression expression_class.new(:where,  'relation')
      subject.add_expression expression_class.new(:order,  'relation')
      subject.add_expression expression_class.new(:limit,  'relation')
      subject.add_expression expression_class.new(:offset, 'relation')
      ar_relation = subject.build_for_find
      assert_not_expression_applied ar_relation, :where,  'relation'
      assert_not_expression_applied ar_relation, :order,  'relation'
      assert_not_expression_applied ar_relation, :limit,  'relation'
      assert_not_expression_applied ar_relation, :offset, 'relation'
    end

    should "return a relation from the record class using `build_for_all`" do
      assert_equal FakeTestRecord.scoped, subject.build_for_all
    end

    should "return a new relation everytime `build_for_all` is called" do
      ar_relation = subject.build_for_all
      assert_not_same ar_relation, subject.build_for_all
    end

    should "apply query expressions of the same type " \
           "in the order they are added using `build_for_all`" do
      [ :first_column, :second_column, :third_column ].each do |column|
        subject.add_expression MR::ReadModel::QueryExpression.new(:joins, column)
      end
      ar_relation = subject.build_for_all
      expected_order = subject.expressions[:joins].map{ |e| [ e.type, e.args ] }
      actual_order   = ar_relation.applied.map{ |e| [ e.type, e.args ] }
      assert_equal expected_order, actual_order
    end

    should "apply query expressions using the args passed to `build_for_all`" do
      subject.add_expression MR::ReadModel::QueryExpression.new(:select){ |c| c }
      ar_relation = subject.build_for_all('some_table.some_column')
      assert_expression_applied ar_relation, :select, 'some_table.some_column'
    end

    should "raise a no record class error using `build_for_all` with no record class" do
      subject.record_class = nil
      assert_raises(MR::ReadModel::NoRecordClassError){ subject.build_for_all }
    end

  end

  class MergeQueryExpressionTests < UnitTests
    desc "MergeQueryExpression"
    setup do
      @ar_relation = FakeTestRecord.scoped
      @expression  = MR::ReadModel::MergeQueryExpression.new(:order, 'relation')
    end
    subject{ @expression }

    should have_readers :type, :query_expression
    should have_imeths :apply_to

    should "build a query expression for a merge" do
      query_expression = subject.query_expression
      assert_instance_of MR::ReadModel::QueryExpression::Static, query_expression
      assert_equal :merge, query_expression.type
      assert_equal [ 'relation' ], query_expression.args
    end

    should "apply it's query expression using `apply_to`" do
      query_expression = subject.query_expression
      subject.apply_to(@ar_relation)
      assert_expression_applied @ar_relation, query_expression.type, 'relation'
    end

  end

  class StaticQueryExpressionTests < UnitTests
    desc "QueryExpression::Static"
    setup do
      @ar_relation = FakeTestRecord.scoped
      @expression  = MR::ReadModel::QueryExpression::Static.new(:select, 'column')
    end
    subject{ @expression }

    should have_readers :type, :args

    should "apply itself to an ActiveRecord relation using `apply_to`" do
      subject.apply_to(@ar_relation)
      assert_expression_applied @ar_relation, subject.type, *subject.args
    end

  end

  class DynamicQueryExpressionTests < UnitTests
    desc "QueryExpression::Dynamic"
    setup do
      @ar_relation = FakeTestRecord.scoped
      block = proc{ 'column' }
      @expression  = MR::ReadModel::QueryExpression::Dynamic.new(:select, &block)
    end
    subject{ @expression }

    should have_readers :type, :block

    should "apply itself to an ActiveRecord relation using `apply_to`" do
      subject.apply_to(@ar_relation, 'test')
      assert_expression_applied @ar_relation, subject.type, 'column'
    end

    should "yield any args to it's block using `apply_to`" do
      yielded = nil
      block = proc{ |args| yielded = args }
      expression = MR::ReadModel::QueryExpression::Dynamic.new(:select, &block)
      expression.apply_to(@ar_relation, 'test')
      assert_equal 'test', yielded
    end

    should "eval it's block in the ActiveRecord relation's scope using `apply_to`" do
      scope = nil
      block = proc{ |args| scope = self }
      expression = MR::ReadModel::QueryExpression::Dynamic.new(:select, &block)
      expression.apply_to(@ar_relation, 'test')
      assert_equal @ar_relation, scope
    end

  end

  class FakeTestRecord
    include MR::FakeRecord

    def self.scoped
      Ardb::RelationSpy.new
    end
  end

end
