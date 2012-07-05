class CreatePlayedTricks < ActiveRecord::Migration
  def change
    create_table :played_tricks do |t|
      t.integer :size
      t.integer :player_id
      t.integer :trick_id

      t.timestamps
    end
  end
end
