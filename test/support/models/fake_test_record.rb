require 'mr/fake_record'
require 'test/support/models/fake_area_record'
require 'test/support/active_record_relation_spy'

class FakeTestRecord
  include MR::FakeRecord

  attribute :name,   :string
  attribute :active, :boolean

  belongs_to :area, 'FakeAreaRecord'

  def self.scoped
    ActiveRecordRelationSpy.new
  end

end
