defmodule Card do
  @insert_task_title_question "Please enter task title"
  @insert_task_status_question "Please enter task status"
  @insert_done "✅ Task added successfully!"
  @insert_failed "❌ Failed to add task"

  @lists_columns ["TODO", "IN PROGRESS", "DONE"]
  @show_lists_failed "❌ Failed to show tasks"

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

      {:error, _reason} ->
        @insert_failed
    end
  end

  def to_columns(tasks) do
    max_length = tasks |> Enum.map(&length/1) |> Enum.max()

    tasks
    |> Enum.map(fn task ->
      pad = List.duplicate("", max_length - length(task))
      task ++ pad
    end)
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  def showLists do
    conn = Database.connect()

    case Exqlite.Sqlite3.prepare(conn, "SELECT * FROM tasks") do
      {:ok, statement} ->
        tasks = loop_rows(conn, statement, [])

        todos =
          Enum.filter(tasks, fn [_id, _title, status] ->
            status === "todo"
          end)
          |> Enum.map(fn [_id, title, _status] -> title end)

        in_progresses =
          Enum.filter(tasks, fn [_id, _title, status] ->
            status === "in progress"
          end)
          |> Enum.map(fn [_id, title, _status] -> title end)

        dones =
          Enum.filter(tasks, fn [_id, _title, status] ->
            status === "done"
          end)
          |> Enum.map(fn [_id, title, _status] -> title end)

        lists = [@lists_columns]
        lists = lists ++ to_columns([todos, in_progresses, dones])

        Prompt.table(lists)

      {:error, _reason} ->
        @show_lists_failed
    end
  end

  defp loop_rows(conn, statement, acc) do
    case Exqlite.Sqlite3.step(conn, statement) do
      {:row, row} ->
        loop_rows(conn, statement, [row | acc])

      :done ->
        Enum.reverse(acc)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
