require 'sqlite3'

def setup_database
  db = SQLite3::Database.new File.join(Dir.home, '.git_jump.sqlite3')

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS branches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_name TEXT NOT NULL,
      branch_name TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  SQL

  db
end

