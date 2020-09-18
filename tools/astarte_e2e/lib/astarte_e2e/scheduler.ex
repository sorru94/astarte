#
# This file is part of Astarte.
#
# Copyright 2020 Ispirata Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule AstarteE2E.Scheduler do
  require Logger

  use GenServer, restart: :transient

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    check_interval_ms =
      Keyword.fetch!(opts, :check_interval_s)
      |> to_ms()

    check_repetitions = Keyword.fetch!(opts, :check_repetitions)

    state = %{check_repetitions: check_repetitions, check_interval_ms: check_interval_ms}
    :timer.send_interval(check_interval_ms, :do_work)

    {:ok, state}
  end

  @impl true
  def handle_info(:do_work, %{check_repetitions: 0} = state) do
    Logger.info("Terminating application successfully.",
      tag: "astarte_e2e_scheduler_termination_success"
    )

    System.stop(0)
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:do_work, state) do
    AstarteE2E.work()

    case state.check_repetitions do
      :infinity ->
        {:noreply, state}

      _ ->
        updated_count = state.check_repetitions - 1
        {:noreply, %{state | check_repetitions: updated_count}}
    end
  end

  defp to_ms(seconds), do: seconds * 1_000
end
