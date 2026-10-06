class UpdateMessagesTextColumn < ActiveRecord::Migration[8.1]
  def up
    # 1. Rename the column from 'text' to 'content'
    rename_column :messages, :text, :content

    # 2. Change the data type from 'string' to 'text'
    change_column :messages, :content, :text
  end

  def down
    # Revert the changes if you run rails db:rollback
    change_column :messages, :content, :string
    rename_column :messages, :content, :text
  end
end
