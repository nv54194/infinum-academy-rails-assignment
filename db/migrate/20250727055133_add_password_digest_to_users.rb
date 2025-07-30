class AddPasswordDigestToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :password_digest, :string

    User.reset_column_information
    User.find_each do |user|
      user.password = SecureRandom.hex(8)
    end
  end

  def down
    remove_column :users, :password_digest
  end
end