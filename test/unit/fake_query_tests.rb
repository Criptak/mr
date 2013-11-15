require 'assert'
require 'mr/fake_query'

require 'mr/fake_record'
require 'mr/model'

class MR::FakeQuery

  class UnitTests < Assert::Context
    desc "MR::FakeQuery"
    setup do
      @models = [
        FakeTestModel.new.tap{ |m| m.save },
        FakeTestModel.new.tap{ |m| m.save },
        FakeTestModel.new.tap{ |m| m.save }
      ]
      @query = MR::FakeQuery.new(@models)
    end
    subject{ @query }

    should have_imeths :models, :results, :count, :paged

    should "return the models and their size with #models and #count" do
      assert_equal @models, subject.models
      assert_equal @models.size, subject.count
    end

    should "return an instance of a `FakePagedQuery` with #paged" do
      assert_instance_of MR::FakePagedQuery, subject.paged
    end

  end

  class FakePagedQueryTests < UnitTests
    desc "MR::FakePagedQuery"
    setup do
      @paged_query = MR::FakePagedQuery.new(@query, 1, 1)
    end
    subject{ @paged_query }

    should have_imeths :page_num, :page_size, :page_offset, :total_count

    should "be a kind of MR::FakeQuery" do
      assert_kind_of MR::FakeQuery, subject
    end

    should "return the first page of models with #models" do
      models = subject.models
      assert_equal @models[0, 1], models
    end

    should "count the first page of models with #count" do
      assert_equal 1, subject.count
    end

    should "count the total number of models with #total_count" do
      assert_equal 3, subject.total_count
    end

  end

  class FakeTestRecord
    include MR::FakeRecord
  end

  class FakeTestModel
    include MR::Model
    record_class FakeTestRecord
  end

end
