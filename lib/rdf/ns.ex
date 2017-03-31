defmodule RDF.NS do
  use RDF.Vocabulary.Namespace

  @vocabdoc """
  The XML Schema datatypes vocabulary.

  See <https://www.w3.org/TR/xmlschema11-2/>
  """
  defvocab XSD,
    base_uri: "http://www.w3.org/2001/XMLSchema#",
    terms:    RDF.Literal.NS.XSD.__terms__

  @vocabdoc """
  The RDF vocabulary.

  See <https://www.w3.org/TR/rdf11-concepts/>
  """
  defvocab RDF,
    base_uri: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    file: "rdf.nt"

  @vocabdoc """
  The RDFS vocabulary.

  See <https://www.w3.org/TR/rdf-schema/>
  """
  defvocab RDFS,
    base_uri: "http://www.w3.org/2000/01/rdf-schema#",
    file: "rdfs.nt"

  @vocabdoc """
  The OWL vocabulary.

  See <https://www.w3.org/TR/owl-overview/>
  """
  defvocab OWL,
    base_uri: "http://www.w3.org/2002/07/owl#",
    file: "owl.nt"

  @vocabdoc """
  The SKOS vocabulary.

  See <http://www.w3.org/TR/skos-reference/>
  """
  defvocab SKOS,
    base_uri: "http://www.w3.org/2004/02/skos/core#",
    file: "skos.nt"

end