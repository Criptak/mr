require 'mr/factory'
require 'test/support/models/image'

module Factory; end
Factory::Image     = MR::Factory.new(Image, ImageRecord)
Factory::FakeImage = MR::Factory.new(Image, FakeImageRecord)
