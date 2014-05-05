require 'mr/read_model/query_expression'

module MR; end
module MR::ReadModel; end
module MR::ReadModel::Querying

  module TestHelpers
    module_function

    def assert_static_expression_added(relation, type, *args)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions.size
        expression = relation.expressions.first
        assert_static_expression expression, type, args
      end
    end

    def assert_dynamic_expression_added(relation, type, block)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions.size
        expression = relation.expressions.first
        assert_dynamic_expression expression, type, block
      end
    end

    def assert_static_merge_expression_added(relation, type, *args)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions.size
        expression = relation.expressions.first
        assert_static_merge_expression expression, type, args
      end
    end

    def assert_dynamic_merge_expression_added(relation, type, block)
      with_backtrace(caller) do
        assert_equal 1, relation.expressions.size
        expression = relation.expressions.first
        assert_dynamic_merge_expression expression, type, block
      end
    end

    def assert_static_expression(expression, type, args)
      expected_class = MR::ReadModel::StaticQueryExpression
      assert_instance_of expected_class, expression
      assert_equal type, expression.type
      assert_equal [*args], expression.args
    end

    def assert_dynamic_expression(expression, type, block)
      expected_class = MR::ReadModel::DynamicQueryExpression
      assert_instance_of expected_class, expression
      assert_equal type,  expression.type
      assert_equal block, expression.block
    end

    def assert_merge_expression(expression, type)
      expected_class = MR::ReadModel::MergeQueryExpression
      assert_instance_of expected_class, expression
      assert_equal expression.type, type
    end

    def assert_static_merge_expression(expression, type, args)
      assert_merge_expression expression, type
      assert_static_expression expression.query_expression, :merge, args
    end

    def assert_dynamic_merge_expression(expression, type, block)
      assert_merge_expression expression, type
      assert_dynamic_expression expression.query_expression, :merge, block
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

end
