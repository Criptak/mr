require 'mr/query'

module MR

  class FakeQuery

    attr_reader :results, :count

    def initialize(results)
      @results = results || []
      @count = @results.size
    end

    def paged(page_num = nil, page_size = nil)
      FakePagedQuery.new(self, page_num, page_size)
    end

  end

  class FakePagedQuery < FakeQuery

    attr_reader :page_num, :page_size, :page_offset, :total_count

    def initialize(query, page_num, page_size)
      @page_num = MR::PagedQuery::PageNumber.new(page_num)
      @page_size = MR::PagedQuery::PageSize.new(page_size)
      @page_offset = MR::PagedQuery::PageOffset.new(@page_num, @page_size)
      @unpaged_results = query.results.dup
      @total_count = @unpaged_results.size

      super(@unpaged_results.dup[@page_offset, @page_size])
    end

  end

end
