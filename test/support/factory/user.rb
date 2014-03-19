require 'mr/factory'
require 'test/support/models/user'

module Factory; end
Factory::User     = MR::Factory.new(User, UserRecord)
Factory::FakeUser = MR::Factory.new(User, FakeUserRecord)
