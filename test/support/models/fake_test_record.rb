require 'mr/fake_record'
require 'test/support/models/_helpers/fake_active_record_relation'

class FakeTestRecord
  include MR::FakeRecord

  attribute :name,   :string
  attribute :active, :boolean

  def self.scoped
    FakeActiveRecordRelation.new
  end

end
