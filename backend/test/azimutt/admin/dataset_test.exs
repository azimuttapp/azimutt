defmodule Azimutt.Admin.DatasetTest do
  use Azimutt.DataCase
  alias Azimutt.Admin.Dataset
  alias Azimutt.Admin.Dataset.Data

  describe "dataset" do
    test "chartjs_data" do
      dataset = %Dataset{name: "Demo", data: [%Data{label: "a", value: 3}]}
      chartjs = %{labels: ["a"], datasets: [%{label: "Demo", data: [3]}]}
      assert chartjs == Dataset.chartjs_data(dataset)
    end

    test "chartjs_daily_data" do
      {:ok, from} = "2022-12-30" |> Timex.parse("{YYYY}-{0M}-{0D}")
      {:ok, to} = "2023-01-02" |> Timex.parse("{YYYY}-{0M}-{0D}")
      dataset = %Dataset{name: "Users", data: [%Data{label: "2022-12-30", value: 3}, %Data{label: "2023-01-02", value: 1}]}
      chartjs = %{labels: ["2022-12-30", "2022-12-31", "2023-01-01", "2023-01-02"], datasets: [%{label: "Users", data: [3, 0, 0, 1]}]}
      assert chartjs == Dataset.chartjs_daily_data([dataset], from, to)
    end
  end
end
