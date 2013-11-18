require 'mr/factory'
require 'test/support/models/area'

module Factory; end
Factory::Area = MR::Factory.new(Area, FakeAreaRecord)
