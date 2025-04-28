defmodule Clikanban do
   def main do
    case Prompt.select("Please select an option", ["New"]) do
      "New" -> Card.create

      _ -> "Please select an valid option"
    end
  end
end
