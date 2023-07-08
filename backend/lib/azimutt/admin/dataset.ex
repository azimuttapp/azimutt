defmodule Azimutt.Admin.Dataset do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Admin.Dataset
  alias Azimutt.Admin.Dataset.Data
  alias Azimutt.Utils.Enumx
  alias Azimutt.Utils.Result

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :name, String.t()
    field :data, list(Data.t())
  end

  typedstruct module: Data, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :label, String.t()
    field :value, integer()
  end

  def from_values(values, name) do
    %Dataset{
      name: name,
      data: values |> Enum.map(fn {label, value} -> %Data{label: label, value: value} end)
    }
  end

  def chartjs_data(dataset) do
    labels = dataset.data |> Enum.map(fn d -> d.label end)

    %{
      labels: labels,
      datasets: [
        %{
          label: dataset.name,
          data: dataset.data |> Enum.map(fn d -> d.value end)
        }
      ]
    }
  end

  def chartjs_daily_data(datasets, from \\ nil, to \\ nil) do
    [start, stop] = build_interval(datasets, "{YYYY}-{0M}-{0D}", from, to)

    generate_date_labels(start, stop, "{YYYY}-{0M}-{0D}", fn d -> Timex.shift(d, days: 1) end)
    |> build_chartjs(datasets)
  end

  def chartjs_weekly_data(datasets, from \\ nil, to \\ nil) do
    [start, stop] = build_interval(datasets, "{YYYY}-{0M}-{0D}", from, to)

    generate_date_labels(start |> Timex.beginning_of_week(:mon), stop, "{YYYY}-{0M}-{0D}", fn d -> Timex.shift(d, days: 7) end)
    |> build_chartjs(datasets)
  end

  def chartjs_monthly_data(datasets, from \\ nil, to \\ nil) do
    [start, stop] = build_interval(datasets, "{YYYY}-{0M}", from, to)

    generate_date_labels(start, stop, "{YYYY}-{0M}", fn d -> Timex.shift(d, months: 1) end)
    |> build_chartjs(datasets)
  end

  defp build_interval(datasets, format, from \\ nil, to \\ nil) do
    if from == nil || to == nil do
      now = DateTime.utc_now()

      dates =
        datasets
        |> Enum.flat_map(fn dataset -> dataset.data |> Enum.flat_map(fn d -> d.label |> Timex.parse(format) |> Result.to_list() end) end)

      start = if from == nil, do: dates |> Enum.min(Date, fn -> now end), else: from
      stop = if to == nil, do: dates |> Enum.max(Date, fn -> now end), else: to
      [start, stop]
    else
      [from, to]
    end
  end

  defp generate_date_labels(from, to, format, step) do
    Stream.unfold(from, fn cur ->
      if Date.compare(cur, to) == :gt do
        nil
      else
        {:ok, label} = cur |> Timex.format(format)
        {label, step.(cur)}
      end
    end)
    |> Enum.to_list()
  end

  defp build_chartjs(labels, datasets) do
    %{
      labels: labels,
      datasets:
        datasets
        |> Enum.map(fn dataset ->
          values_map = dataset.data |> Enum.map(fn d -> {d.label, d.value} end) |> Map.new()

          %{
            label: dataset.name,
            data: labels |> Enum.map(fn label -> values_map |> Map.get(label, 0) end)
          }
        end)
    }
  end

  # works only for cumulative metrics
  def grouped(chartjs, size, label_transform) do
    %{
      labels: chartjs.labels |> Enumx.grouped(size) |> Enum.map(&List.last/1),
      datasets:
        chartjs.datasets
        |> Enum.map(fn dataset ->
          %{
            label: label_transform.(dataset.label),
            data: dataset.data |> Enumx.grouped(size) |> Enum.map(&Enum.sum/1)
          }
        end)
    }
  end
end
