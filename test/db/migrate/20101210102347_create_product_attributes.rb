class CreateProductAttributes < ActiveRecord::Migration
  def self.up
    create_table :product_attributes do |t|
      t.references :product
      t.string :name
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :product_attributes
  end
end
