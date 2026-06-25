class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    enable_extension "citext" unless extension_enabled?("citext")

    create_table :users do |t|
      t.string  :name, null: false
      t.citext  :email, null: false
      t.string  :password_digest, null: false
      t.string  :current_city
      t.boolean :admin, null: false, default: false

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
