defmodule Card do

  @insert_task_title_question "Please enter task title"
  @insert_task_status_question "Please enter task status"
  @insert_done "✅ Task added successfully!"
  @insert_failed "❌ Failed to add task"


  def create do
    card_title = Prompt.text(@insert_task_title_question)
    card_status = Prompt.select(@insert_task_status_question, ["todo", "in progress", "done"])

    conn = Database.connect()

    case Exqlite.Sqlite3.prepare(conn, "INSERT INTO tasks (title, status) VALUES (?,?)") do
      {:ok, statement} ->
        Exqlite.Sqlite3.bind(statement, [card_title, card_status])

        case Exqlite.Sqlite3.step(conn, statement) do
          :done -> @insert_done
          {:error, _reason} -> @insert_failed
        end
      {:error, _reason} -> @insert_failed
    end
  end
end
