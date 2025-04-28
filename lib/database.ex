defmodule Database do
  def connect do
      case Exqlite.Sqlite3.open("database.db") do
        {:ok, conn} -> conn
        {:error, _reason } -> raise "Connection failed"
      end
  end

  def setup do
      conn = connect()

      query = "
      CREATE TABLE IF NOT EXISTS tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      status TEXT NOT NULL
      );
    "
      case Exqlite.Sqlite3.execute(conn, query) do
        :ok -> :ok
        {:error, :invalid_connection} -> raise "Setup failed"
      end
  end
end
