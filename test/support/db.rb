require 'logger'

Ardb.configure do |c|
  c.root_path   File.expand_path("../../..", __FILE__)
  c.schema_path File.join(c.root_path, "test/support/schema.rb")
  c.logger      Logger.new(File.open("log/db.log", 'w'))

  c.db.adapter  'sqlite3'
  c.db.database ':memory:'
end
