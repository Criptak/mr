require 'mr/record'
require 'mr/query'

module MR; end
module MR::ReadModel

  module QueryExpression
    def self.new(type, *args, &block)
      if !args.empty?
        StaticQueryExpression.new(type, *args)
      elsif block
        DynamicQueryExpression.new(type, &block)
      else
        raise InvalidQueryExpressionError, "must be passed args or a block"
      end
    end
  end

  class StaticQueryExpression
    attr_reader :type, :args

    def initialize(type, *args)
      @type = type
      @args = args
    end

    # apply_to has to take a second arg that it ignores, this is so it has the
    # same interface as `DynamicQueryExpression` (which actually needs the
    # second arg)
    def apply_to(relation, ignored = nil)
      relation.send(@type, *@args)
    end
  end

  class DynamicQueryExpression
    attr_reader :type, :block

    def initialize(type, &block)
      @type  = type
      @block = block
    end

    def apply_to(relation, args)
      relation.send(@type, relation.instance_exec(args, &@block))
    end
  end

  class MergeQueryExpression
    attr_accessor :type, :query_expression

    def initialize(type, *args, &block)
      @type = type
      @query_expression = QueryExpression.new(:merge, *args, &block)
    end

    def apply_to(relation, args = nil)
      @query_expression.apply_to(relation, args)
    end
  end

  InvalidQueryExpressionError = Class.new(RuntimeError)

end
