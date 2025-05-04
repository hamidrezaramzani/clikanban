defmodule Clikanban do
  def main do
    Database.setup()
    Card.start()
  end
end
