defmodule Unshell.Agents.Supervisor do
  @moduledoc "Starts and restarts agent workers."
  use DynamicSupervisor

  alias Unshell.Agents.Worker

  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 3)

  def start_agent(name, workspace) when is_binary(name) do
    spec = {Worker, name: name, workspace: workspace}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, reason} -> {:error, "could not start #{name}: #{inspect(reason)}"}
    end
  end

  def running, do: DynamicSupervisor.which_children(__MODULE__) |> length()
end
