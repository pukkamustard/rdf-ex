defmodule RDF.Turtle.Encoder do
  @moduledoc false

  use RDF.Serialization.Encoder

  alias RDF.Turtle.Encoder.State
  alias RDF.{Literal, BlankNode, Description, List}

  @indentation_char " "
  @indentation 4

  @xsd_string  RDF.Datatype.NS.XSD.string
  @native_supported_datatypes [
    RDF.Datatype.NS.XSD.boolean,
    RDF.Datatype.NS.XSD.integer,
    RDF.Datatype.NS.XSD.double
  ]
  @rdf_type RDF.type
  @rdf_nil  RDF.nil


  def encode(data, opts \\ []) do
    with base         = Keyword.get(opts, :base) |> init_base(),
         prefixes     = Keyword.get(opts, :prefixes, %{}) |> init_prefixes(),
         {:ok, state} = State.start_link(data, base, prefixes) do
      try do
        State.preprocess(state)

        {:ok,
            base_directive(base) <>
            prefix_directives(prefixes) <>
            graph_statements(state)
        }
      after
        State.stop(state)
      end
    end
  end

  defp init_base(nil), do: nil

  defp init_base(base) do
    with base = to_string(base) do
      if String.ends_with?(base, ~w[/ #]) do
        {:ok, base}
      else
        IO.warn("invalid base: #{base}")
        {:bad, base}
      end
    end
  end

  defp init_prefixes(nil), do: %{}

  defp init_prefixes(prefixes) do
    Enum.reduce prefixes, %{}, fn {prefix, uri}, reverse ->
      Map.put(reverse, RDF.uri(uri), to_string(prefix))
    end
  end


  defp base_directive(nil),            do: ""
  defp base_directive({_, base}),      do: "@base <#{base}> .\n"

  defp prefix_directive({ns, prefix}), do: "@prefix #{prefix}: <#{to_string(ns)}> .\n"

  defp prefix_directives(prefixes) do
    case Enum.map(prefixes, &prefix_directive/1) do
      []       -> ""
      prefixes -> Enum.join(prefixes, "") <> "\n"
    end
  end


  defp graph_statements(state) do
    State.data(state)
    |> RDF.Data.descriptions
    |> Enum.map(&description_statements(&1, state))
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp description_statements(description, state, nesting \\ 0) do
    with %BlankNode{} <- description.subject,
         ref_count when ref_count < 2 <-
            State.bnode_ref_counter(state, description.subject)
    do
      unrefed_bnode_subject_term(description, ref_count, state, nesting)
    else
      _ -> full_description_statements(description, state, nesting)
    end
  end

  defp full_description_statements(subject, description, state, nesting) do
    with nesting = nesting + @indentation do
      subject <> newline_indent(nesting) <> (
        predications(description, state, nesting)
      ) <> " .\n"
    end
  end

  defp full_description_statements(description, state, nesting) do
    term(description.subject, state, :subject, nesting)
    |> full_description_statements(description, state, nesting)
  end

  defp blank_node_property_list(description, state, nesting) do
    with indented = nesting + @indentation do
      "[" <> newline_indent(indented) <>
        predications(description, state, indented) <>
        newline_indent(nesting) <> "]"
    end
  end

  defp predications(description, state, nesting) do
    description.predications
    |> Enum.map(&predication(&1, state, nesting))
    |> Enum.join(" ;" <> newline_indent(nesting))
  end

  defp predication({predicate, objects}, state, nesting) do
    term(predicate, state, :predicate, nesting) <> " " <> (
      objects
       |> Enum.map(fn {object, _} -> term(object, state, :object, nesting) end)
       |> Enum.join(", ") # TODO: split if the line gets too long
    )
  end


  defp unrefed_bnode_subject_term(bnode_description, ref_count, state, nesting) do
    if valid_list_node?(bnode_description.subject, state) do
      case ref_count do
        0 ->
          bnode_description.subject
          |> list_term(state, nesting)
          |> full_description_statements(
              list_subject_description(bnode_description), state, nesting)
        1 ->
          nil
        _ ->
          raise "Internal error: This shouldn't happen. Please raise an issue in the RDF.ex project with the input document causing this error."
      end
    else
      case ref_count do
        0 ->
          blank_node_property_list(bnode_description, state, nesting) <> " .\n"
        1 ->
          nil
        _ ->
          raise "Internal error: This shouldn't happen. Please raise an issue in the RDF.ex project with the input document causing this error."
      end
    end
  end

  defp list_subject_description(description) do
    with description = Description.delete_predicates(description, [RDF.first, RDF.rest]) do
      if Enum.count(description.predications) == 0 do
        # since the Turtle grammar doesn't allow bare lists, we add a statement
        description |> RDF.type(RDF.List)
      else
        description
      end
    end
  end

  defp unrefed_bnode_object_term(bnode, ref_count, state, nesting) do
    if valid_list_node?(bnode, state) do
      list_term(bnode, state, nesting)
    else
      if ref_count == 1 do
        State.data(state)
        |> RDF.Data.description(bnode)
        |> blank_node_property_list(state, nesting)
      else
        raise "Internal error: This shouldn't happen. Please raise an issue in the RDF.ex project with the input document causing this error."
      end
    end
  end

  defp valid_list_node?(bnode, state) do
     MapSet.member?(State.list_nodes(state), bnode)
  end

  defp list_term(head, state, nesting) do
    head
    |> State.list_values(state)
    |> term(state, :list, nesting)
  end


  defp term(@rdf_type, _, :predicate, _), do: "a"
  defp term(@rdf_nil, _, _, _),           do: "()"

  defp term(%URI{} = uri, state, _, _) do
    based_name(uri, State.base(state)) ||
      prefixed_name(uri, State.prefixes(state)) ||
      "<#{to_string(uri)}>"
  end

  defp term(%BlankNode{} = bnode, state, position, nesting)
        when position in ~w[object list]a do
    if (ref_count = State.bnode_ref_counter(state, bnode)) <= 1 do
      unrefed_bnode_object_term(bnode, ref_count, state, nesting)
    else
      to_string(bnode)
    end
  end

  defp term(%BlankNode{} = bnode, _, _, _),
    do: to_string(bnode)

  defp term(%Literal{value: value, language: language}, _,_ , _) when not is_nil(language),
    do: ~s["#{value}"@#{language}]

  defp term(%Literal{value: value, language: language}, _,_ , _) when not is_nil(language),
    do: ~s["#{value}"@#{language}]

  defp term(%Literal{datatype: @xsd_string} = literal, _, _,_),
    do: literal |> Literal.lexical |> quoted()

  defp term(%Literal{datatype: datatype} = literal, state, _, nesting)
        when datatype in @native_supported_datatypes do
    if Literal.valid?(literal) do
      literal |> Literal.canonical |> Literal.lexical
    else
      typed_literal_term(literal, state, nesting)
    end
  end

  defp term(%Literal{datatype: datatype} = literal, state, _, nesting),
    do: typed_literal_term(literal, state, nesting)

  defp term(list, state, _, nesting) when is_list(list) do
    "(" <>
      (
        list
        |> Enum.map(&term(&1, state, :list, nesting))
        |> Enum.join(" ")
      ) <>
      ")"
  end

  defp based_name(%URI{} = uri, base), do: based_name(URI.to_string(uri), base)
  defp based_name(uri, {:ok, base}) do
    if String.starts_with?(uri, base) do
      "<#{String.slice(uri, String.length(base)..-1)}>"
    end
  end

  defp based_name(_, _), do: nil


  defp typed_literal_term(%Literal{datatype: datatype} = literal, state, nesting),
    do: ~s["#{Literal.lexical(literal)}"^^#{term(datatype, state, :datatype, nesting)}]


  def prefixed_name(uri, prefixes) do
    with {ns, name} <- split_uri(uri) do
      case prefixes[ns] do
        nil    -> nil
        prefix -> prefix <> ":" <> name
      end
    end
  end


  defp split_uri(%URI{fragment: fragment} = uri) when not is_nil(fragment),
    do: {%URI{uri | fragment: ""}, fragment}

  defp split_uri(%URI{path: nil}),
    do: nil

  defp split_uri(%URI{path: path} = uri) do
    with [{pos, _}] = Regex.run(~r"[^/]*$"u, path, return: :index),
         {ns_path, name} = String.split_at(path, pos) do
      {%URI{uri | path: ns_path}, name}
    end
  end

  defp quoted(string) do
    if String.contains?(string, ["\n", "\r"]) do
      ~s["""#{string}"""]
    else
      ~s["#{escape(string)}"]
    end
  end

  defp escape(string) do
    string
    |> String.replace("\\", "\\\\\\\\")
    |> String.replace("\b", "\\b")
    |> String.replace("\f", "\\f")
    |> String.replace("\t", "\\t")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\"", ~S[\"])
  end


  defp newline_indent(nesting),
    do: "\n" <> String.duplicate(@indentation_char, nesting)
end