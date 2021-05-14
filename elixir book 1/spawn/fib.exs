defmodule FibSolver do
  def fib(scheduler) do
    send(scheduler, {:ready, self()})

    receive do
      {:fib, n, client} ->
        send(client, {:answer, n, fib_calc(n), self()})
        fib(scheduler)

      {:shutdown} ->
        exit(:normal)
    end
  end

  def fib_calc(0), do: 0
  def fib_calc(1), do: 1
  def fib_calc(n), do: fib_calc(n - 1) + fib_calc(n - 2)
end

defmodule FibAgent do

  def start_link do
    Agent.start_link(fn -> %{ 0 => 0, 1 => 1 } end)
  end

  def fib(pid, n) when n >= 0 do
    Agent.get_and_update(pid, &do_fib(&1, n))
  end

  defp do_fib(cache,n) do
    case cache[n] do
      nil ->
        { n_1, cache } = do_fib(cache, n-1)
        result = n_1 + cache[n-2]
        { result, Map.put(cache, n, result)}
      cached_value ->
        {cached_value, cache}
    end
  end

end


defmodule Scheduler do
  def run(num_processes, module, func, to_calculate) do
    (1..num_processes)
    |> Enum.map(fn (_)-> spawn(module, func, [self()]) end)
    |> schedule_processes(to_calculate, [])
  end

  defp schedule_processes(processes, queue, results) do
    receive do
      {:ready, pid} when queue != []->
        [next | tail] = queue
        send(pid, {:fib, next, self()})
        schedule_processes(processes, tail, results)

      {:ready, pid} ->
        send(pid, {:shutdown})

        if length(processes) > 1 do
          schedule_processes(List.delete(processes, pid), queue, results)
        else
          Enum.sort(results, fn {n1, _}, {n2, _} -> n1 <= n2 end)
        end

      {:answer, number, result, _pid} ->
        schedule_processes(processes, queue, [{number, result} | results])
    end
  end
end

# to_process = List.duplicate(37, 28)
#
# Enum.each(1..10, fn num_processes ->
#   {time, result} =
#     :timer.tc(
#       Scheduler,
#       :run,
#       [num_processes, FibSolver, :fib, to_process]
#     )
#
#   if num_processes == 1 do
#     IO.puts(inspect(result))
#     IO.puts("\n # time (s)")
#   end
#
#   :io.format("~2B       ~.2f~n", [num_processes, time / 1_000_000.0])
# end)
# Scheduler.run(1,FibSolver, :fib, '%%%%%%%')
