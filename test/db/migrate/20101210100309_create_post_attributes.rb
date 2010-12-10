class CreatePostAttributes < ActiveRecord::Migration
  def self.up
    create_table :post_attributes do |t|
      t.references :post
      t.string :name
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :post_attributes
  end
end
