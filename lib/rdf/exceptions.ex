defmodule RDF.InvalidURIError do
  defexception [:message]
end

defmodule RDF.InvalidLiteralError do
  defexception [:message]
end

defmodule RDF.Triple.InvalidSubjectError do
  defexception [:subject]

  def message(%{subject: subject}) do
    "'#{inspect(subject)}' is not a valid subject of a RDF.Triple"
  end
end

defmodule RDF.Triple.InvalidPredicateError do
  defexception [:predicate]

  def message(%{predicate: predicate}) do
    "'#{inspect(predicate)}' is not a valid predicate of a RDF.Triple"
  end
end

defmodule RDF.Quad.InvalidGraphContextError do
  defexception [:graph_context]

  def message(%{graph_context: graph_context}) do
    "'#{inspect(graph_context)}' is not a valid graph context of a RDF.Quad"
  end
end


defmodule RDF.Vocabulary.InvalidBaseURIError do
  defexception [:message]
end

defmodule RDF.Vocabulary.UndefinedTermError do
  defexception [:message]
end

defmodule RDF.Vocabulary.InvalidTermError do
  defexception [:message]
end


defmodule RDF.InvalidRepoURLError do
  defexception [:message, :url]

  def exception(opts) do
    url = Keyword.fetch!(opts, :url)
    msg = Keyword.fetch!(opts, :message)
    msg = "invalid url #{url}, #{msg}"
    %__MODULE__{message: msg, url: url}
  end
end