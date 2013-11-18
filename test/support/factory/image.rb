require 'mr/factory'
require 'test/support/models/image'

module Factory; end
Factory::Image = MR::Factory.new(Image, FakeImageRecord)
