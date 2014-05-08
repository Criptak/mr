require 'assert'
require 'mr/read_model/query_expression'

require 'ardb/relation_spy'
require 'mr/fake_record'
require 'test/support/read_model/querying'

module MR::ReadModel

  class UnitTests < Assert::Context
    include Querying::TestHelpers

  end

  class QueryExpressionTests < UnitTests
    desc "QueryExpression"
    subject{ QueryExpression }

    should "return the correct type of expression using `new`" do
      expression = subject.new(:select, 'column')
      assert_instance_of StaticQueryExpression, expression
      expression = subject.new(:select){ 'column' }
      assert_instance_of DynamicQueryExpression, expression
    end

    should "raise an invalid error when not passed args or a block" do
      assert_raises(InvalidQueryExpressionError){ subject.new(:select) }
    end

  end

  class StaticQueryExpressionTests < UnitTests
    desc "StaticQueryExpression"
    setup do
      @ar_relation = FakeTestRecord.scoped
      @expression  = StaticQueryExpression.new(:select, 'column')
    end
    subject{ @expression }

    should have_readers :type, :args

    should "apply itself to an ActiveRecord relation using `apply_to`" do
      subject.apply_to(@ar_relation)
      assert_expression_applied @ar_relation, subject.type, *subject.args
    end

  end

  class DynamicQueryExpressionTests < UnitTests
    desc "DynamicQueryExpression"
    setup do
      @ar_relation = FakeTestRecord.scoped
      block = proc{ 'column' }
      @expression  = DynamicQueryExpression.new(:select, &block)
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
      expression = DynamicQueryExpression.new(:select, &block)
      expression.apply_to(@ar_relation, 'test')
      assert_equal 'test', yielded
    end

    should "eval it's block in the ActiveRecord relation's scope using `apply_to`" do
      scope = nil
      block = proc{ |args| scope = self }
      expression = DynamicQueryExpression.new(:select, &block)
      expression.apply_to(@ar_relation, 'test')
      assert_equal @ar_relation, scope
    end

  end

  class MergeQueryExpressionTests < UnitTests
    desc "MergeQueryExpression"
    setup do
      @ar_relation = FakeTestRecord.scoped
      @expression  = MergeQueryExpression.new(:order, 'relation')
    end
    subject{ @expression }

    should have_readers :type, :query_expression
    should have_imeths :apply_to

    should "build a query expression for a merge" do
      query_expression = subject.query_expression
      assert_instance_of StaticQueryExpression, query_expression
      assert_equal :merge, query_expression.type
      assert_equal [ 'relation' ], query_expression.args
    end

    should "apply it's query expression using `apply_to`" do
      query_expression = subject.query_expression
      subject.apply_to(@ar_relation)
      assert_expression_applied @ar_relation, query_expression.type, 'relation'
    end

  end

  class SubQueryExpressionTests < UnitTests
    desc "SubQueryExpression"
    setup do
      @type = :joins
      @args = [ :inner ]
      @block = proc do
        read_model do
          select{ |args| args[:select] }
          from FakeTestRecord
        end
      end
      @expression = SubQueryExpression.new(@type, *@args, &@block)
    end
    subject{ @expression }

    should have_readers :subquery_type, :subquery_args, :subquery_block

    should "know its subquery attributes" do
      assert_equal @type,  subject.subquery_type
      assert_equal @args,  subject.subquery_args
      assert_equal @block, subject.subquery_block
    end

    should "build a subquery and apply its SQL to a relation using `apply_to`" do
      apply_args = { :select => 'column' }
      ar_relation = FakeTestRecord.scoped
      subject.apply_to(ar_relation, apply_args)

      subquery = SubQueryExpression::TYPES[@type].new(*@args)
      subquery.instance_exec(apply_args, &@block)
      expected_sql = subquery.build_subquery_sql(apply_args)
      assert_expression_applied ar_relation, :joins, expected_sql
    end

    should "not apply an incomplete supquery to a relation using `apply_to`" do
      expression = SubQueryExpression.new(@type, *@args){ }
      ar_relation = FakeTestRecord.scoped
      expression.apply_to(ar_relation, {})

      assert_empty ar_relation.applied
    end

    should "raise an argument error if a block isn't passed" do
      assert_raises(ArgumentError){ SubQueryExpression.new(@type, *@args) }
    end

  end

  class SubQueryTests < UnitTests
    desc "SubQuery"
    setup do
      @subquery = SubQuery.new
    end
    subject{ @subquery }

    should have_readers :read_model_class
    should have_imeths :read_model
    should have_imeths :build_subquery_sql
    should have_imeths :complete?

    should "default its read model class to `nil`" do
      assert_nil subject.read_model_class
    end

    should "not be complete by default" do
      assert_false subject.complete?
    end

    should "build a read model class using `read_model`" do
      subject.read_model do
        select 'column'
        from FakeTestRecord
      end

      assert_includes MR::ReadModel, subject.read_model_class
      relation = subject.read_model_class.relation
      assert_static_expression_added relation, :select, 'column'
    end

    should "be complete if its built a read model class" do
      subject.read_model{ }
      assert_true subject.complete?
    end

    should "build the subquery's SQL using `build_subquery_sql`" do
      subject.read_model{ from FakeTestRecord }

      expected = subject.read_model_class.relation.build_for_all.to_sql
      assert_equal expected, subject.build_subquery_sql
    end

  end

  class JoinSubQueryTests < UnitTests
    desc "JoinSubQuery"
    setup do
      @subquery = JoinSubQuery.new(:inner)
    end
    subject{ @subquery }

    should have_readers :type, :alias_name, :conditions
    should have_imeths :as, :on, :build_subquery_sql

    should "know its type" do
      assert_equal :inner, subject.type
    end

    should "default its alias name and conditions" do
      assert_nil subject.alias_name
      assert_nil subject.conditions
    end

    should "allow setting its alias name using `as`" do
      subject.as('my_table')
      assert_equal 'my_table', subject.alias_name
    end

    should "allow setting its conditions using `on`" do
      subject.on('my_table.my_column')
      assert_equal 'my_table.my_column', subject.conditions
    end

  end

  class JoinSubQueryBuildSubquerySQLTests < JoinSubQueryTests
    setup do
      @read_model_proc = proc do
        select 'table.column'
        from FakeTestRecord
      end
    end

    should "build a inner join subquery's SQL using `build_subquery_sql`" do
      subquery = JoinSubQuery.new(:inner)
      subquery.read_model(&@read_model_proc)

      subquery_sql = subquery.read_model_class.relation.build_for_all.to_sql
      expected = "INNER JOIN (#{subquery_sql})"
      assert_equal expected, subquery.build_subquery_sql
    end

    should "build a left join subquery's SQL using `build_subquery_sql`" do
      subquery = JoinSubQuery.new(:left)
      subquery.read_model(&@read_model_proc)

      subquery_sql = subquery.read_model_class.relation.build_for_all.to_sql
      expected = "LEFT OUTER JOIN (#{subquery_sql})"
      assert_equal expected, subquery.build_subquery_sql
    end

    should "build a right join subquery's SQL using `build_subquery_sql`" do
      subquery = JoinSubQuery.new(:right)
      subquery.read_model(&@read_model_proc)

      subquery_sql = subquery.read_model_class.relation.build_for_all.to_sql
      expected = "RIGHT OUTER JOIN (#{subquery_sql})"
      assert_equal expected, subquery.build_subquery_sql
    end

    should "build a full join subquery's SQL using `build_subquery_sql`" do
      subquery = JoinSubQuery.new(:full)
      subquery.read_model(&@read_model_proc)

      subquery_sql = subquery.read_model_class.relation.build_for_all.to_sql
      expected = "FULL OUTER JOIN (#{subquery_sql})"
      assert_equal expected, subquery.build_subquery_sql
    end

    should "use the join subquery's alias and conditions when building its SQL" do
      subquery = JoinSubQuery.new(:inner)
      subquery.read_model(&@read_model_proc)
      subquery.as('my_table')
      subquery.on('my_table.column = 1')

      subquery_sql = subquery.read_model_class.relation.build_for_all.to_sql
      expected = "INNER JOIN (#{subquery_sql}) AS my_table ON my_table.column = 1"
      assert_equal expected, subquery.build_subquery_sql
    end

  end

  class FakeTestRecord
    include MR::FakeRecord

    def self.scoped
      Ardb::RelationSpy.new
    end
  end

end
