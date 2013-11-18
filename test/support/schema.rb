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
    t.boolean "favorite", :default => false
    t.string  "parent_type"
    t.integer "parent_id"
    t.integer "created_by_id"
  end

end