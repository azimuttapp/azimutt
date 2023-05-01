defmodule Azimutt.Analyzer.Schema do
  @moduledoc "Schema definition returned by the Analyzer"
  use TypedStruct
  alias Azimutt.Analyzer.Schema.Check
  alias Azimutt.Analyzer.Schema.Column
  alias Azimutt.Analyzer.Schema.ColumnLink
  alias Azimutt.Analyzer.Schema.ColumnRef
  alias Azimutt.Analyzer.Schema.Index
  alias Azimutt.Analyzer.Schema.PrimaryKey
  alias Azimutt.Analyzer.Schema.Relation
  alias Azimutt.Analyzer.Schema.Table
  alias Azimutt.Analyzer.Schema.Type
  alias Azimutt.Analyzer.Schema.Unique

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :tables, list(Table.t())
    field :relations, list(Relation.t())
    field :types, list(Type.t())
  end

  typedstruct module: Table, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :schema, String.t()
    field :table, String.t()
    field :view, boolean()
    field :columns, list(Column.t())
    field :primaryKey, PrimaryKey.t() | nil
    field :uniques, list(Unique.t())
    field :indexes, list(Index.t())
    field :checks, list(Check.t())
    field :comment, String.t() | nil
  end

  typedstruct module: Column, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :name, String.t()
    field :type, String.t()
    field :nullable, boolean()
    field :default, String.t() | nil
    field :comment, String.t() | nil
  end

  typedstruct module: PrimaryKey, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :name, String.t() | nil
    field :columns, list(String.t())
  end

  typedstruct module: Unique, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :name, String.t()
    field :columns, list(String.t())
    field :definition, String.t() | nil
  end

  typedstruct module: Index, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :name, String.t()
    field :columns, list(String.t())
    field :definition, String.t() | nil
  end

  typedstruct module: Check, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :name, String.t()
    field :columns, list(String.t())
    field :predicate, String.t() | nil
  end

  typedstruct module: Relation, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :name, String.t()
    field :src, ColumnRef.t()
    field :ref, ColumnRef.t()
  end

  typedstruct module: ColumnRef, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :schema, String.t()
    field :table, String.t()
    field :column, String.t()
  end

  typedstruct module: ColumnLink, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :src, String.t()
    field :ref, String.t()
  end

  typedstruct module: Type, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :schema, String.t()
    field :name, String.t()
    field :values, list(String.t()) | nil
  end
end
