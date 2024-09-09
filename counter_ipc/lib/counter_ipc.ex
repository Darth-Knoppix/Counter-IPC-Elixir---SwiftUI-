defmodule CounterIPC do
  import Logger

  def connect(path) do
    {:ok, sck} = :socket.open(:local, :stream, %{})
    :ok = :socket.bind(sck, %{family: :local, path: path})
    File.chmod!(path, 0o777)
    :ok = :socket.listen(sck)

    accept(sck)
  rescue
    _e in ErlangError ->
      Logger.error("Something went wrong during connection.")
  end

  def accept(socket) do
    {:ok, client} = :socket.accept(socket)
    Logger.info("Serving #{inspect(client)}")

    spawn_monitor(__MODULE__, :serve, [client])

    accept(socket)
  end

  def serve(socket) do
    message = read(socket)

    case message do
      "increment()" ->
        Logger.info("Increment count")
        Counter.increment()
        write(Integer.to_string(Counter.value()), socket)

      "decrement()" ->
        Logger.info("Decrement count")
        Counter.decrement()
        write(Integer.to_string(Counter.value()), socket)

      "value" ->
        Logger.info("Get current count")
        write(Integer.to_string(Counter.value()), socket)
    end

    serve(socket)
  end

  def read(socket) do
    result = :socket.recv(socket, 0)

    case result do
      {:ok, msg} ->
        msg = String.trim(msg)
        Logger.info("Received \"#{msg}\"")
        msg

      {:error, reason} ->
        Logger.info("Closing socket #{inspect(socket)} because #{inspect(reason)}")
        :socket.close(socket)
        nil
    end
  end

  def write(msg, socket) do
    result = :socket.send(socket, msg <> "\r\n")

    case result do
      :ok ->
        nil

      {:error, :closed} ->
        Logger.info("Socket #{inspect(socket)} closed")

      {:error, reason} ->
        Logger.info("Closing socket #{inspect(socket)} because #{inspect(reason)}")
        :socket.close(socket)
    end
  end
end

Counter.start_link(0)
socketname = "/tmp/.test-ipc.sock"
File.rm(socketname)
IO.puts("Listening on #{socketname}")
CounterIPC.connect(socketname)
