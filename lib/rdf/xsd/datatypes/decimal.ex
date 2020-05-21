defmodule RDF.XSD.Decimal do
  @moduledoc """
  `RDF.XSD.Datatype` for XSD decimals.
  """

  @type valid_value :: Decimal.t()

  use RDF.XSD.Datatype.Primitive,
    name: "decimal",
    id: RDF.Utils.Bootstrapping.xsd_iri("decimal")

  alias RDF.XSD
  alias Elixir.Decimal, as: D


  def_applicable_facet XSD.Facets.MinInclusive
  def_applicable_facet XSD.Facets.MaxInclusive
  def_applicable_facet XSD.Facets.MinExclusive
  def_applicable_facet XSD.Facets.MaxExclusive

  @doc false
  def min_inclusive_conform?(min_inclusive, value, _lexical) do
    not (D.cmp(value, D.new(min_inclusive)) == :lt)
  end

  @doc false
  def max_inclusive_conform?(max_inclusive, value, _lexical) do
    not (D.cmp(value, D.new(max_inclusive)) == :gt)
  end

  @doc false
  def min_exclusive_conform?(min_exclusive, value, _lexical) do
    D.cmp(value, D.new(min_exclusive)) == :gt
  end

  @doc false
  def max_exclusive_conform?(max_exclusive, value, _lexical) do
    D.cmp(value, D.new(max_exclusive)) == :lt
  end


  @impl XSD.Datatype
  def lexical_mapping(lexical, opts) do
    if String.contains?(lexical, ~w[e E]) do
      @invalid_value
    else
      case D.parse(lexical) do
        {:ok, decimal} -> elixir_mapping(decimal, opts)
        :error -> @invalid_value
      end
    end
  end

  @impl XSD.Datatype
  @spec elixir_mapping(valid_value | integer | float | any, Keyword.t()) :: value
  def elixir_mapping(value, _)

  def elixir_mapping(%D{coef: coef}, _) when coef in ~w[qNaN sNaN inf]a,
    do: @invalid_value

  def elixir_mapping(%D{} = decimal, _),
    do: canonical_decimal(decimal)

  def elixir_mapping(value, opts) when is_integer(value),
    do: value |> D.new() |> elixir_mapping(opts)

  def elixir_mapping(value, opts) when is_float(value),
    do: value |> D.from_float() |> elixir_mapping(opts)

  def elixir_mapping(_, _), do: @invalid_value

  @doc false
  @spec canonical_decimal(valid_value) :: valid_value
  def canonical_decimal(decimal)

  def canonical_decimal(%D{coef: 0} = decimal),
    do: %{decimal | exp: -1}

  def canonical_decimal(%D{coef: coef, exp: 0} = decimal),
    do: %{decimal | coef: coef * 10, exp: -1}

  def canonical_decimal(%D{coef: coef, exp: exp} = decimal)
      when exp > 0,
      do: canonical_decimal(%{decimal | coef: coef * 10, exp: exp - 1})

  def canonical_decimal(%D{coef: coef} = decimal)
      when Kernel.rem(coef, 10) != 0,
      do: decimal

  def canonical_decimal(%D{coef: coef, exp: exp} = decimal),
    do: canonical_decimal(%{decimal | coef: Kernel.div(coef, 10), exp: exp + 1})

  @impl XSD.Datatype
  @spec canonical_mapping(valid_value) :: String.t()
  def canonical_mapping(value)

  def canonical_mapping(%D{sign: sign, coef: :qNaN}),
    do: if(sign == 1, do: "NaN", else: "-NaN")

  def canonical_mapping(%D{sign: sign, coef: :sNaN}),
    do: if(sign == 1, do: "sNaN", else: "-sNaN")

  def canonical_mapping(%D{sign: sign, coef: :inf}),
    do: if(sign == 1, do: "Infinity", else: "-Infinity")

  def canonical_mapping(%D{} = decimal),
    do: D.to_string(decimal, :normal)

  @impl RDF.Literal.Datatype
  def do_cast(value)

  def do_cast(%XSD.String{} = xsd_string) do
    xsd_string.value |> new() |> canonical()
  end

  def do_cast(literal) do
    cond do
      XSD.Boolean.datatype?(literal) ->
        case literal.value do
          false -> new(0.0)
          true  -> new(1.0)
        end

      XSD.Integer.datatype?(literal) ->
        new(literal.value)

      # we're catching XSD.Floats with this too
      is_float(literal.value) and XSD.Double.datatype?(literal) ->
        new(literal.value)

      true ->
        super(literal)
    end
  end


  def equal_value?(left, right), do: XSD.Numeric.equal_value?(left, right)

  @impl RDF.Literal.Datatype
  def compare(left, right), do: XSD.Numeric.compare(left, right)

  @doc """
  The number of digits in the XML Schema canonical form of the literal value.
  """
  @spec digit_count(RDF.Literal.t()) :: non_neg_integer | nil
  def digit_count(%__MODULE__{} = literal), do: do_digit_count(literal)

  def digit_count(literal) do
    cond do
      XSD.Integer.datatype?(literal) -> XSD.Integer.digit_count(literal)
      datatype?(literal) -> do_digit_count(literal)
      true -> nil
    end
  end

  defp do_digit_count(%datatype{} = literal) do
    if datatype.valid?(literal) do
      literal
      |> datatype.canonical()
      |> datatype.lexical()
      |> String.replace(".", "")
      |> String.replace("-", "")
      |> String.length()
    end
  end

  @doc """
  The number of digits to the right of the decimal point in the XML Schema canonical form of the literal value.
  """
  @spec fraction_digit_count(RDF.Literal.t()) :: non_neg_integer | nil
  def fraction_digit_count(%__MODULE__{} = literal), do: do_fraction_digit_count(literal)

  def fraction_digit_count(literal) do
    cond do
      XSD.Integer.datatype?(literal) -> 0
      datatype?(literal) -> do_fraction_digit_count(literal)
      true -> nil
    end
  end

  defp do_fraction_digit_count(%datatype{} = literal) do
    if datatype.valid?(literal) do
      [_, fraction] =
        literal
        |> datatype.canonical()
        |> datatype.lexical()
        |> String.split(".")

      String.length(fraction)
    end
  end
end
