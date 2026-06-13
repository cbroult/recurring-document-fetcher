# frozen_string_literal: true

require "sqlite3"
require "digest"
require "fileutils"

module RecurringDocumentFetcher
  class DownloadTracker
    DEFAULT_DB_PATH = File.join(Configuration::DEFAULT_CONFIG_DIR, "downloads.db")

    def initialize(db_path: DEFAULT_DB_PATH)
      @db_path = db_path
      @db = nil
    end

    def record(provider:, document_id:, document_date:, file_path:, file_size:)
      checksum = Digest::SHA256.file(file_path).hexdigest
      params = [provider.to_s, document_id.to_s, document_date.to_s,
                Time.now.to_s, file_path, checksum, file_size, 1]
      db.execute(<<~SQL, params)
        INSERT OR REPLACE INTO downloads
          (provider, document_id, document_date, downloaded_at, file_path, file_checksum, file_size, valid)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      SQL
    end

    def downloaded?(provider:, document_id:)
      result = db.get_first_value(
        "SELECT COUNT(*) FROM downloads WHERE provider = ? AND document_id = ?",
        [provider.to_s, document_id.to_s]
      )
      result.positive?
    end

    def mark_invalid(provider:, document_id:)
      db.execute(
        "UPDATE downloads SET valid = 0 WHERE provider = ? AND document_id = ?",
        [provider.to_s, document_id.to_s]
      )
    end

    def mark_for_redownload(provider:, document_id:)
      db.execute(
        "DELETE FROM downloads WHERE provider = ? AND document_id = ?",
        [provider.to_s, document_id.to_s]
      )
    end

    def history(provider: nil, since: nil)
      sql = "SELECT * FROM downloads WHERE 1=1"
      params = []

      if provider
        sql += " AND provider = ?"
        params << provider.to_s
      end

      if since
        sql += " AND downloaded_at >= ?"
        params << since.to_s
      end

      sql += " ORDER BY downloaded_at DESC"

      db.execute(sql, params).map do |row|
        {
          id: row[0],
          provider: row[1],
          document_id: row[2],
          document_date: row[3],
          downloaded_at: row[4],
          file_path: row[5],
          file_checksum: row[6],
          file_size: row[7],
          valid: row[8] == 1
        }
      end
    end

    def close
      @db&.close
      @db = nil
    end

    private

    def db
      @db ||= open_database
    end

    def open_database
      FileUtils.mkdir_p(File.dirname(@db_path))
      database = SQLite3::Database.new(@db_path)
      create_schema(database)
      database
    end

    def create_schema(database)
      database.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS downloads (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          provider TEXT NOT NULL,
          document_id TEXT NOT NULL,
          document_date TEXT,
          downloaded_at TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_checksum TEXT NOT NULL,
          file_size INTEGER NOT NULL,
          valid INTEGER DEFAULT 1,
          UNIQUE(provider, document_id)
        )
      SQL
    end
  end
end
