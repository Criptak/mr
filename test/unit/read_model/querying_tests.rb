require 'assert'
require 'mr/read_model/querying'

require 'ardb/relation_spy'
require 'mr/fake_record'
require 'test/support/read_model/querying'

module MR::ReadModel::Querying

  class UnitTests < Assert::Context
    include MR::ReadModel::Querying::TestHelpers

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
    should have_imeths :inner_join_subquery
    should have_imeths :left_outer_join_subquery, :left_join_subquery
    should have_imeths :right_outer_join_subquery, :right_join_subquery
    should have_imeths :full_outer_join_subquery, :full_join_subquery

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

    should "return the expression using `select`" do
      select_sql = "some_table.some_column AS 'something'"
      expression = subject.select select_sql
      assert_static_expression expression, :select, select_sql
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

    should "return the expression using `joins`" do
      join_args = [ :some_table, :other_table ]
      expression = subject.joins(*join_args)
      assert_static_expression expression, :joins, join_args
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

    should "return the merge expression using `where`" do
      merge_args = 'fake-relation'
      expression = subject.where(merge_args)
      assert_static_merge_expression expression, :where, merge_args
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

    should "return the merge expression using `order`" do
      merge_args = 'fake-relation'
      expression = subject.order(merge_args)
      assert_static_merge_expression expression, :order, merge_args
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

    should "return the expression using `group`" do
      group_args = 'some_table.some_column'
      expression = subject.group(group_args)
      assert_static_expression expression, :group, group_args
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

    should "return the expression using `having`" do
      having_args = 'COUNT(*) > 0'
      expression = subject.having(having_args)
      assert_static_expression expression, :having, having_args
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

    should "return the expression using `limit`" do
      limit_args = 1
      expression = subject.limit(limit_args)
      assert_static_expression expression, :limit, limit_args
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

    should "return the expression using `offset`" do
      offset_args = 1
      expression = subject.offset(offset_args)
      assert_static_expression expression, :offset, offset_args
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

    should "return the merge expression using `merge`" do
      merge_args = 'fake-relation'
      expression = subject.merge(merge_args)
      assert_static_merge_expression expression, :merge, merge_args
    end

    should "add a join subquery to the relation with `inner_join_subquery`" do
      subquery_proc = proc{ as('my_table') }
      expression = subject.inner_join_subquery(&subquery_proc)
      assert_inner_join_subquery_added @relation, subquery_proc
    end

    should "return the subquery expression using `inner_join_subquery`" do
      subquery_proc = proc{ as('my_table') }
      expression = subject.inner_join_subquery(&subquery_proc)
      assert_join_subquery_expression expression, :inner, subquery_proc
    end

    should "add a join subquery to the relation with `left_outer_join_subquery`" do
      subquery_proc = proc{ as('my_table') }
      expression = subject.left_outer_join_subquery(&subquery_proc)
      assert_left_outer_join_subquery_added @relation, subquery_proc
    end

    should "return the subquery expression using `left_outer_join_subquery`" do
      subquery_proc = proc{ as('my_table') }
      expression = subject.left_outer_join_subquery(&subquery_proc)
      assert_join_subquery_expression expression, :left, subquery_proc
    end

    should "add a join subquery to the relation with `right_outer_join_subquery`" do
      subquery_proc = proc{ as('my_table') }
      expression = subject.right_outer_join_subquery(&subquery_proc)
      assert_right_outer_join_subquery_added @relation, subquery_proc
    end

    should "return the subquery expression using `right_outer_join_subquery`" do
      subquery_proc = proc{ as('my_table') }
      expression = subject.right_outer_join_subquery(&subquery_proc)
      assert_join_subquery_expression expression, :right, subquery_proc
    end

    should "add a join subquery to the relation with `full_outer_join_subquery`" do
      subquery_proc = proc{ as('my_table') }
      expression = subject.full_outer_join_subquery(&subquery_proc)
      assert_full_outer_join_subquery_added @relation, subquery_proc
    end

    should "return the subquery expression using `full_outer_join_subquery`" do
      subquery_proc = proc{ as('my_table') }
      expression = subject.full_outer_join_subquery(&subquery_proc)
      assert_join_subquery_expression expression, :full, subquery_proc
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
      assert_raises(ArgumentError){ subject.inner_join_subquery }
      assert_raises(ArgumentError){ subject.left_outer_join_subquery }
      assert_raises(ArgumentError){ subject.right_outer_join_subquery }
      assert_raises(ArgumentError){ subject.full_outer_join_subquery }
    end

  end

  class FindTests < WithFromRecordClassTests
    desc "find"
    setup do
      @read_model_class.class_eval do
        attr_accessor :id
        select :id
        limit 1
        def initialize(record_data)
          self.id = record_data.id
        end
      end
      @fake_record = FakeTestRecord.new
      @ar_relation_spy.results = [ @fake_record ]
      @result = @read_model_class.find(@fake_record.id)
    end
    subject{ @result }

    should "return the matching read model" do
      assert_kind_of @read_model_class, subject
      assert_equal @fake_record.id, subject.id
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
    should have_imeths :build_for_all, :build_for_find

    should "default it's record class and query expressions" do
      relation = MR::ReadModel::Relation.new
      assert_nil relation.record_class
      assert_equal [], relation.expressions
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
        subject.expressions << MR::ReadModel::QueryExpression.new(:joins, column)
      end
      ar_relation = subject.build_for_find
      expected_order = subject.expressions.map{ |e| [ e.type, e.args ] }
      actual_order   = ar_relation.applied.map{ |e| [ e.type, e.args ] }
      assert_equal expected_order, actual_order
    end

    should "apply query expressions using the args passed to `build_for_find`" do
      subject.expressions << MR::ReadModel::QueryExpression.new(:select){ |c| c }
      ar_relation = subject.build_for_find('some_table.some_column')
      assert_expression_applied ar_relation, :select, 'some_table.some_column'
    end

    should "not apply where, order, limit or offset expressions using `build_for_find`" do
      expression_class = MR::ReadModel::MergeQueryExpression
      subject.expressions << expression_class.new(:where,  'relation')
      subject.expressions << expression_class.new(:order,  'relation')
      subject.expressions << expression_class.new(:limit,  'relation')
      subject.expressions << expression_class.new(:offset, 'relation')
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
        subject.expressions << MR::ReadModel::QueryExpression.new(:joins, column)
      end
      ar_relation = subject.build_for_all
      expected_order = subject.expressions.map{ |e| [ e.type, e.args ] }
      actual_order   = ar_relation.applied.map{ |e| [ e.type, e.args ] }
      assert_equal expected_order, actual_order
    end

    should "apply query expressions using the args passed to `build_for_all`" do
      subject.expressions << MR::ReadModel::QueryExpression.new(:select){ |c| c }
      ar_relation = subject.build_for_all('some_table.some_column')
      assert_expression_applied ar_relation, :select, 'some_table.some_column'
    end

    should "raise a no record class error using `build_for_all` with no record class" do
      subject.record_class = nil
      assert_raises(MR::ReadModel::NoRecordClassError){ subject.build_for_all }
    end

  end

  class FakeTestRecord
    include MR::FakeRecord

    def self.scoped
      Ardb::RelationSpy.new
    end
  end

end
