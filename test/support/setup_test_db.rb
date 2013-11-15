require 'ardb'
Ardb.config.db_file = 'test/support/db'
Ardb.init

require 'ardb/test_helpers'
Ardb::TestHelpers.reset_db
