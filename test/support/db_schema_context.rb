require 'assert'
require 'active_record'

class DBSchemaTests < Assert::Context

  setup_once do
    ActiveRecord::Base.establish_connection({
      :adapter   => 'sqlite3',
      :database  => ':memory:',
      :verbosity => 'quiet'
    })
    DBSetup.load_schema
  end

  module DBSetup
    module_function

    def load_schema
      # silence STDOUT
      current_stdout = $stdout.dup
      $stdout = File.new('/dev/null', 'w')
      ActiveRecord::Schema.define(:version => 1) do

        create_table "areas" do |t|
          t.string "name"
        end

        create_table "users" do |t|
          t.string  "name"
          t.string  "email"
          t.boolean "active"
          t.integer "area_id"
          t.timestamps
        end

        create_table "comments" do |t|
          t.string  "message"
          t.integer "user_id"
        end

      end
      $stdout = current_stdout
    end

  end

end
