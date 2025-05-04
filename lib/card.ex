defmodule Card do
  @start_question "Please select an option"
  @start_select_invalid "Please select a valid option"

  @insert_task_title_question "Please enter task title"
  @insert_task_status_question "Please enter task status"
  @insert_done "✅ Task added successfully!"
  @insert_failed "❌ Failed to add task"

  @lists_columns ["TODO", "IN PROGRESS", "DONE"]
  @show_lists_failed "❌ Failed to show tasks"
  @list_action_question "What do you want to do with these lists"

  def start do
    case Prompt.select(@start_question, ["New", "List"]) do
      "New" -> create()
      "List" -> showLists()
      _ -> @start_select_invalid
    end
  end

  def create do
    card_title = Prompt.text(@insert_task_title_question)
    card_status = Prompt.select(@insert_task_status_question, ["todo", "in progress", "done"])

    conn = Database.connect()

    case Exqlite.Sqlite3.prepare(conn, "SELECT * FROM tasks ORDER BY id DESC LIMIT 1;") do
      {:ok, statement} ->
        tasks = loop_rows(conn, statement, [])

        IO.inspect(tasks)

        card_number =
          if length(tasks) == 0 do
            "t_1"
          else
            last_task = List.last(tasks)

            last_number =
              last_task
              |> Enum.at(2)
              |> String.last()
              |> String.to_integer()

            "t_" <> Integer.to_string(last_number + 1)
          end

        case Exqlite.Sqlite3.prepare(
               conn,
               "INSERT INTO tasks (title,number, status) VALUES (?,?,?)"
             ) do
          {:ok, statement} ->
            Exqlite.Sqlite3.bind(statement, [card_title, card_number, card_status])

            case Exqlite.Sqlite3.step(conn, statement) do
              :done -> @insert_done
              {:error, _reason} -> @insert_failed
            end

          {:error, _reason} ->
            @insert_failed
        end
    end
  end

  def showLists do
    conn = Database.connect()

    case Exqlite.Sqlite3.prepare(conn, "SELECT * FROM tasks") do
      {:ok, statement} ->
        tasks = loop_rows(conn, statement, [])

        todos =
          Enum.filter(tasks, fn [_id, _title, _task_number, status] ->
            status === "todo"
          end)
          |> Enum.map(fn [_id, title, task_number, _status] -> "#{task_number} - #{title}" end)

        in_progresses =
          Enum.filter(tasks, fn [_id, _title, _task_number, status] ->
            status === "in progress"
          end)
          |> Enum.map(fn [_id, title, task_number, _status] -> "#{task_number} - #{title}" end)

        dones =
          Enum.filter(tasks, fn [_id, _title, _task_number, status] ->
            status === "done"
          end)
          |> Enum.map(fn [_id, title, task_number, _status] -> "#{task_number} - #{title}" end)

        lists = [@lists_columns]
        lists = lists ++ to_columns([todos, in_progresses, dones])

        Prompt.table(lists)

        list_action = Prompt.select(@list_action_question, ["Delete", "Move", "Back"])

        case list_action do
          "Back" ->
            start()

            "Delete"
        end

      {:error, _reason} ->
        @show_lists_failed
    end
  end

  defp to_columns(tasks) do
    max_length = tasks |> Enum.map(&length/1) |> Enum.max()

    tasks
    |> Enum.map(fn task ->
      pad = List.duplicate("", max_length - length(task))
      task ++ pad
    end)
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
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
