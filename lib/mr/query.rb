require 'active_record'

module MR

  class Query

    attr_reader :model_class, :relation
    protected :model_class, :relation

    def initialize(model_class, relation)
      @model_class = model_class
      @relation = relation
    end

    def models
      @relation.all.map{|record| @model_class.new(record) }
    end

    def count
      @relation.count
    end

    def paged(page_num = nil, page_size = nil)
      PagedQuery.new(self, page_num, page_size)
    end

  end

  class PagedQuery < Query
    attr_reader :page_num, :page_size, :page_offset

    def initialize(query, page_num = nil, page_size = nil)
      @page_num    = PageNumber.new(page_num)
      @page_size   = PageSize.new(page_size)
      @page_offset = PageOffset.new(@page_num, @page_size)

      @unpaged_relation = query.relation.dup
      relation = query.relation.offset(@page_offset).limit(@page_size)
      super query.model_class, relation
    end

    # This isn't done in the `initialize` because it runs a query (which is
    # expensive) and should only be done when it's needed. If it's never used
    # then, running it in the `initialize` would be wasteful.
    def total_count
      @unpaged_relation.count
    end

    module PageNumber
      def self.new(number)
        number && number.to_i > 0 ? number.to_i : 1
      end
    end

    module PageSize
      def self.new(number)
        number && number.to_i > 0 ? number.to_i : 25
      end
    end

    module PageOffset
      def self.new(page_number, page_size)
        (page_number - 1) * page_size
      end
    end

  end

end
