class CreateAcRec < ActiveRecord::Migration
  def change
    create_table :ac_recs do |t|
      t.string :stringy
      t.integer :inty
      t.float :floaty
      t.boolean :booly
      t.datetime :datey
    end
  end
end
