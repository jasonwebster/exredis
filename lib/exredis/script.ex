defmodule Exredis.Script do
  defmacro __using__(_) do
    quote do
      import Exredis.Script
    end
  end

  defmacro defredis_script(name, file_path: file_path) do
    case File.read(file_path) do
      {:ok, content} -> quote do: defredis_script(unquote(name), unquote(content))
      _ -> :erlang.error "Script file is missing at #{file_path}"
    end
  end
  defmacro defredis_script(name, script) do
    quote do
      @script_sha :crypto.hash(:sha, unquote(script))
      def unquote(name)(client, keys \\ [], argv \\ []) do
        query_args = [length(keys)] ++ keys ++ argv
        case Exredis.query client, ["EVALSHA", @script_sha] ++ query_args do
          <<"NOSCRIPT", _ :: binary>> ->
            Exredis.query client, ["EVAL", unquote(script)] ++ query_args
          reply -> reply
        end
      end
    end
  end
end


