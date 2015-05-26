class CreateCachedPostResponses < ActiveRecord::Migration
  def change
    create_table :cached_post_responses do |t|
      t.string :hash_key
      t.text :duplication_key
      t.text :response

      t.timestamps
    end
    add_index :cached_post_responses, :hash_key
  end
end
