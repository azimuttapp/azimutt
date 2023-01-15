defmodule Azimutt.Admin.Dataset do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Admin.Dataset
  alias Azimutt.Admin.Dataset.Data
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

  def chartjs_daily_data(datasets), do: chartjs_date_data(datasets, "{YYYY}-{0M}-{0D}")
  def chartjs_monthly_data(datasets), do: chartjs_date_data(datasets, "{YYYY}-{0M}")

  defp chartjs_date_data(datasets, format) do
    dates =
      datasets
      |> Enum.flat_map(fn dataset ->
        dataset.data |> Enum.flat_map(fn d -> d.label |> Timex.parse(format) |> Result.to_list() end)
      end)

    start = dates |> Enum.min(Date)
    stop = dates |> Enum.max(Date)
    # TODO: inject correct step instead of generating for each day and then dedup :/
    labels = Date.range(start, stop) |> Enum.flat_map(fn d -> d |> Timex.format(format) |> Result.to_list() end) |> Enum.dedup()

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
end
