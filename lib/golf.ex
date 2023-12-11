defmodule Golf do
  @id_length 6
  def id_length(), do: @id_length

  @doc """
  Generates a random 6 character id.
  https://gist.github.com/danschultzer/99c21ba403fd7f49a26cc40571ff5cce
  """
  def gen_id() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
    |> String.downcase()
  end

  def subscribe(topic) when is_binary(topic) do
    Phoenix.PubSub.subscribe(Golf.PubSub, topic)
  end

  def broadcast(topic, msg) when is_binary(topic) do
    Phoenix.PubSub.broadcast(Golf.PubSub, topic, msg)
  end

  def broadcast_from(topic, msg) when is_binary(topic) do
    Phoenix.PubSub.broadcast_from(Golf.PubSub, self(), topic, msg)
  end

  def rotate(list, n) do
    {left, right} = Enum.split(list, n)
    right ++ left
  end
end
