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

  SubQuery = Class.new
  JoinSubQuery = Class.new(SubQuery)

  class SubQueryExpression
    TYPES = {
      :joins => JoinSubQuery
    }.freeze

    attr_reader :subquery_type, :subquery_args, :subquery_block
    alias :type :subquery_type

    def initialize(type, *subquery_args, &block)
      @subquery_type  = type
      @subquery_args  = subquery_args
      @subquery_block = block
      raise ArgumentError, "a block must be provided" unless block
    end

    def apply_to(relation, args = nil)
      subquery = TYPES[@subquery_type].new(*@subquery_args)
      subquery.instance_exec(args, &@subquery_block)
      return relation unless subquery.complete?
      subquery_sql = subquery.build_subquery_sql(args)
      QueryExpression.new(@subquery_type, subquery_sql).apply_to(relation)
    end
  end

  class SubQuery
    attr_reader :read_model_class

    def read_model(&block)
      @read_model_class = Class.new{ include MR::ReadModel }
      @read_model_class.class_eval(&block)
    end

    def build_subquery_sql(args = nil)
      @read_model_class.relation.build_for_all(args).to_sql
    end

    def complete?
      !!@read_model_class
    end
  end

  class JoinSubQuery < SubQuery
    attr_reader :type, :alias_name, :conditions

    JOIN_SQL = Hash.new{ "JOIN" }.tap do |h|
      h[:inner] = "INNER JOIN"
      h[:left]  = "LEFT OUTER JOIN"
      h[:right] = "RIGHT OUTER JOIN"
      h[:full]  = "FULL OUTER JOIN"
    end

    def initialize(type)
      @type       = type
      @alias_name = nil
      @conditions = nil
    end

    def as(alias_name)
      @alias_name = alias_name
    end

    def on(conditions)
      @conditions = conditions
    end

    def build_subquery_sql(args = nil)
      subquery_sql =  "#{JOIN_SQL[@type]} (#{super})"
      subquery_sql += " AS #{@alias_name}" if @alias_name
      subquery_sql += " ON #{@conditions}" if @conditions
      subquery_sql
    end
  end

  InvalidQueryExpressionError = Class.new(RuntimeError)

end
