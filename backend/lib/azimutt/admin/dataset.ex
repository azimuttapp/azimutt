defmodule Azimutt.Admin.Dataset do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Admin.Dataset
  alias Azimutt.Admin.Dataset.Data
  alias Azimutt.Utils.Enumx

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

  def chartjs_daily_data(datasets, from, to) do
    generate_date_labels(from, to, "{YYYY}-{0M}-{0D}", fn d -> Timex.shift(d, days: 1) end)
    |> build_chartjs(datasets)
  end

  def chartjs_weekly_data(datasets, from, to) do
    generate_date_labels(from |> Timex.beginning_of_week(:mon), to, "{YYYY}-{0M}-{0D}", fn d -> Timex.shift(d, days: 7) end)
    |> build_chartjs(datasets)
  end

  def chartjs_monthly_data(datasets, from, to) do
    generate_date_labels(from, to, "{YYYY}-{0M}", fn d -> Timex.shift(d, months: 1) end)
    |> build_chartjs(datasets)
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
