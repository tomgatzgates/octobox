class ChangeTextToMediumTextInSubjects < ActiveRecord::Migration[5.2]
  def change
    change_column :subjects, :body, :text, limit: 16.megabytes - 1
  end
end
