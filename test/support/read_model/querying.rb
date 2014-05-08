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

    def assert_inner_join_subquery_added(relation, block)
      with_backtrace(caller) do
        assert_join_subquery_added(relation, :inner, block)
      end
    end

    def assert_left_outer_join_subquery_added(relation, block)
      with_backtrace(caller) do
        assert_join_subquery_added(relation, :left, block)
      end
    end

    def assert_right_outer_join_subquery_added(relation, block)
      with_backtrace(caller) do
        assert_join_subquery_added(relation, :right, block)
      end
    end

    def assert_full_outer_join_subquery_added(relation, block)
      with_backtrace(caller) do
        assert_join_subquery_added(relation, :full, block)
      end
    end

    def assert_join_subquery_added(relation, type, block)
      assert_equal 1, relation.expressions.size
      expression = relation.expressions.first
      expected_class = MR::ReadModel::SubQueryExpression
      assert_instance_of expected_class, expression
      assert_join_subquery_expression expression, type, block
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

    def assert_subquery_expression(expression, type)
      expected_class = MR::ReadModel::SubQueryExpression
      assert_kind_of expected_class, expression
      assert_equal type, expression.subquery_type
    end

    def assert_join_subquery_expression(expression, type, block)
      assert_subquery_expression expression, :joins
      assert_includes type, expression.subquery_args
      assert_equal block, expression.subquery_block
    end

    def assert_expression_applied(relation_spy, type, *args)
      with_backtrace(caller) do
        message = "couldn't find an applied #{type} expression " \
                  "with #{args.inspect} args"
        assert_not_nil find_applied(relation_spy, type, args), message
      end
    end

    def assert_not_expression_applied(relation_spy, type, *args)
      with_backtrace(caller) do
        message = "found an applied #{type} expression " \
                  "with #{args.inspect} args"
        assert_nil find_applied(relation_spy, type, args), message
      end
    end

    def find_applied(relation_spy, type, args)
      relation_spy.applied.detect{ |e| e.type == type && e.args == args }
    end

  end

end
