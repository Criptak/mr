require 'ardb'
Ardb.config.db_file = 'test/support/db'
Ardb.init

require 'ardb/test_helpers'
Ardb::TestHelpers.reset_db

require 'assert'
class DbTests < Assert::Context
  around do |block|
    ActiveRecord::Base.transaction do
      block.call
      raise ActiveRecord::Rollback
    end
  end
end
