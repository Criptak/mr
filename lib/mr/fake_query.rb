module MR

  class FakeQuery
    attr_reader :models, :count

    def initialize(models)
      @models = models
      @count  = models.size
    end

    def paged(page_num = nil, page_size = nil)
      FakePagedQuery.new(self, page_num, page_size)
    end

  end

  class FakePagedQuery < FakeQuery
    attr_reader :page_num, :page_size, :page_offset, :total_count

    def initialize(query, page_num, page_size)
      @page_num    = MR::PagedQuery::PageNumber.new(page_num)
      @page_size   = MR::PagedQuery::PageSize.new(page_size)
      @page_offset = MR::PagedQuery::PageOffset.new(@page_num, @page_size)
      @unpaged_models = query.models.dup
      @total_count    = @unpaged_models.size

      super @unpaged_models.dup[@page_offset, @page_size]
    end

  end

end
