defmodule Clikanban do
   def main do
    case Prompt.select("Please select an option", ["New", "List"]) do
      "New" -> Card.create
      "List" -> Card.showLists

      _ -> "Please select an valid option"
    end
  end
end
