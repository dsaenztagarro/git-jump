# frozen_string_literal: true

require "fileutils"
require "time"

module GitJump
  # Handles SQLite database operations for branch tracking
  class Database
    attr_reader :db_path

    def initialize(db_path)
      @db_path = db_path
      @db = nil
    end

    # Lazy-load database connection
    def db
      @db ||= begin
        require "sqlite3" unless defined?(SQLite3)
        ensure_database_directory!
        connection = SQLite3::Database.new(db_path)
        connection.results_as_hash = true
        migrate!(connection)
        connection
      end
    end

    def migrate!(connection)
      connection.execute <<-SQL
        CREATE TABLE IF NOT EXISTS projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          path TEXT NOT NULL UNIQUE,
          basename TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      SQL

      connection.execute <<-SQL
        CREATE TABLE IF NOT EXISTS branches (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          position INTEGER NOT NULL DEFAULT 0,
          last_visited_at TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
          UNIQUE(project_id, name)
        );
      SQL

      connection.execute <<-SQL
        CREATE INDEX IF NOT EXISTS idx_branches_project_position#{" "}
          ON branches(project_id, position);
      SQL
    end

    def find_or_create_project(path, basename)
      project = db.execute(
        "SELECT * FROM projects WHERE path = ?",
        [path]
      ).first

      return project if project

      now = Time.now.iso8601(3)
      db.execute(
        "INSERT INTO projects (path, basename, created_at, updated_at) VALUES (?, ?, ?, ?)",
        [path, basename, now, now]
      )

      db.execute("SELECT * FROM projects WHERE path = ?", [path]).first
    end

    def add_branch(project_id, branch_name)
      now = Time.now.iso8601(3)

      # Try to insert, if already exists, update last_visited_at
      db.execute(
        <<-SQL,
          INSERT INTO branches (project_id, name, position, last_visited_at, created_at)
          VALUES (?, ?, 0, ?, ?)
          ON CONFLICT(project_id, name) DO UPDATE SET
            last_visited_at = ?,
            position = 0
        SQL
        [project_id, branch_name, now, now, now]
      )

      # Reorder positions based on last_visited_at
      reorder_branches(project_id)
    end

    def list_branches(project_id, limit: nil)
      sql = "SELECT * FROM branches WHERE project_id = ? ORDER BY position ASC, last_visited_at DESC"
      sql += " LIMIT ?" if limit

      params = limit ? [project_id, limit] : [project_id]
      db.execute(sql, params)
    end

    def next_branch(project_id, current_branch)
      branches = list_branches(project_id)
      return nil if branches.empty?

      current_index = branches.index { |b| b["name"] == current_branch }

      if current_index.nil?
        branches.first["name"]
      elsif current_index == branches.length - 1
        branches.first["name"]
      else
        branches[current_index + 1]["name"]
      end
    end

    def branch_at_index(project_id, index)
      branches = list_branches(project_id)
      return nil if branches.empty? || index < 1 || index > branches.length

      branches[index - 1]["name"]
    end

    def clear_branches(project_id, keep_patterns)
      return 0 if keep_patterns.empty?

      branches = list_branches(project_id)
      deleted = 0

      branches.each do |branch|
        branch_name = branch["name"]
        should_keep = keep_patterns.any? { |pattern| branch_name.match?(Regexp.new(pattern)) }

        unless should_keep
          db.execute("DELETE FROM branches WHERE id = ?", [branch["id"]])
          deleted += 1
        end
      end

      reorder_branches(project_id)
      deleted
    end

    def cleanup_old_branches(project_id, max_count)
      branches = list_branches(project_id)
      return 0 if branches.length <= max_count

      to_delete = branches[max_count..]
      to_delete.each do |branch|
        db.execute("DELETE FROM branches WHERE id = ?", [branch["id"]])
      end

      reorder_branches(project_id)
      to_delete.length
    end

    def count_branches(project_id)
      db.execute(
        "SELECT COUNT(*) as count FROM branches WHERE project_id = ?",
        [project_id]
      ).first["count"]
    end

    def project_stats(project_id)
      {
        total_branches: count_branches(project_id),
        most_recent: list_branches(project_id, limit: 1).first
      }
    end

    def close
      db&.close
    end

    private

    def ensure_database_directory!
      dir = File.dirname(db_path)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
    end

    def reorder_branches(project_id)
      branches = db.execute(
        "SELECT id FROM branches WHERE project_id = ? ORDER BY last_visited_at DESC",
        [project_id]
      )

      branches.each_with_index do |branch, index|
        db.execute("UPDATE branches SET position = ? WHERE id = ?", [index, branch["id"]])
      end
    end
  end
end
