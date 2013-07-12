require 'mr/fake_record'
require 'test/support/models/area'

class FakeAreaRecord
  include MR::FakeRecord
  model_class Area

  attribute :name, :string

end
