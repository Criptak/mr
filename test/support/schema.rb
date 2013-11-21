ActiveRecord::Schema.define(:version => 1) do

  create_table :areas do |t|
    t.string  :name
    t.boolean :active
    t.float   :ratio
    t.text    :description
    t.float   :percentage
    t.time    :meeting_time
  end

  create_table :users do |t|
    t.string    :name
    t.integer   :number
    t.decimal   :salary
    t.date      :started_on
    t.timestamp :dob
    t.integer   :area_id
  end

  create_table :images do |t|
    t.string  :file_path
    t.binary  :data
    t.integer :user_id
  end

  create_table :comments do |t|
    t.text     :body
    t.string   :parent_type
    t.integer  :parent_id
    t.datetime :created_at
    t.integer  :created_by_id
  end

end
