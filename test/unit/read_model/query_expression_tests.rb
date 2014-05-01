require 'assert'
require 'mr/read_model/query_expression'

require 'ardb/relation_spy'
require 'mr/fake_record'
require 'test/support/read_model/querying'

module MR::ReadModel::QueryExpression

  class UnitTests < Assert::Context
    include MR::ReadModel::Querying::TestHelpers

  end

  class StaticQueryExpressionTests < UnitTests
    desc "StaticQueryExpression"
    setup do
      @ar_relation = FakeTestRecord.scoped
      @expression  = MR::ReadModel::StaticQueryExpression.new(:select, 'column')
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
      @expression  = MR::ReadModel::DynamicQueryExpression.new(:select, &block)
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
      expression = MR::ReadModel::DynamicQueryExpression.new(:select, &block)
      expression.apply_to(@ar_relation, 'test')
      assert_equal 'test', yielded
    end

    should "eval it's block in the ActiveRecord relation's scope using `apply_to`" do
      scope = nil
      block = proc{ |args| scope = self }
      expression = MR::ReadModel::DynamicQueryExpression.new(:select, &block)
      expression.apply_to(@ar_relation, 'test')
      assert_equal @ar_relation, scope
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
      assert_instance_of MR::ReadModel::StaticQueryExpression, query_expression
      assert_equal :merge, query_expression.type
      assert_equal [ 'relation' ], query_expression.args
    end

    should "apply it's query expression using `apply_to`" do
      query_expression = subject.query_expression
      subject.apply_to(@ar_relation)
      assert_expression_applied @ar_relation, query_expression.type, 'relation'
    end

  end

  class FakeTestRecord
    include MR::FakeRecord

    def self.scoped
      Ardb::RelationSpy.new
    end
  end

end
