defmodule RDF.NQuads.EncoderTest do
  use ExUnit.Case, async: false

  alias RDF.NQuads

  doctest NQuads.Encoder

  alias RDF.{Dataset, Graph}
  alias RDF.NS.XSD

  import RDF.Sigils

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://example.org/#",
    terms: [], strict: false


  describe "serializing a graph" do
    test "an empty graph is serialized to an empty string" do
      assert NQuads.Encoder.encode!(Graph.new) == ""
    end

    test "statements with IRIs only" do
      assert NQuads.Encoder.encode!(Graph.new [
          {EX.S1, EX.p1, EX.O1},
          {EX.S1, EX.p1, EX.O2},
          {EX.S1, EX.p2, EX.O3},
          {EX.S2, EX.p3, EX.O4},
        ]) ==
        """
        <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> .
        <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O2> .
        <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O3> .
        <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O4> .
        """
    end

    test "statements with literals" do
      assert NQuads.Encoder.encode!(Graph.new [
          {EX.S1, EX.p1, ~L"foo"},
          {EX.S1, EX.p1, ~L"foo"en},
          {EX.S1, EX.p2, 42},
          {EX.S2, EX.p3, RDF.literal("strange things", datatype: EX.custom)},
        ]) ==
        """
        <http://example.org/#S1> <http://example.org/#p1> "foo"@en .
        <http://example.org/#S1> <http://example.org/#p1> "foo" .
        <http://example.org/#S1> <http://example.org/#p2> "42"^^<#{XSD.integer}> .
        <http://example.org/#S2> <http://example.org/#p3> "strange things"^^<#{EX.custom}> .
        """
    end

    test "statements with blank nodes" do
      assert NQuads.Encoder.encode!(Graph.new [
          {EX.S1, EX.p1, RDF.bnode(1)},
          {EX.S1, EX.p1, RDF.bnode("foo")},
          {EX.S1, EX.p1, RDF.bnode(:bar)},
        ]) ==
        """
        <http://example.org/#S1> <http://example.org/#p1> _:1 .
        <http://example.org/#S1> <http://example.org/#p1> _:bar .
        <http://example.org/#S1> <http://example.org/#p1> _:foo .
        """
    end
  end

  describe "serializing a dataset" do
    test "an empty dataset is serialized to an empty string" do
      assert NQuads.Encoder.encode!(Dataset.new) == ""
    end

    test "statements with IRIs only" do
      assert NQuads.Encoder.encode!(Dataset.new [
          {EX.S1, EX.p1, EX.O1, EX.G},
          {EX.S1, EX.p1, EX.O2, EX.G},
          {EX.S1, EX.p2, EX.O3, EX.G},
          {EX.S2, EX.p3, EX.O4},
        ]) ==
        """
        <http://example.org/#S2> <http://example.org/#p3> <http://example.org/#O4> .
        <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O1> <http://example.org/#G> .
        <http://example.org/#S1> <http://example.org/#p1> <http://example.org/#O2> <http://example.org/#G> .
        <http://example.org/#S1> <http://example.org/#p2> <http://example.org/#O3> <http://example.org/#G> .
        """
    end

    test "statements with literals" do
      assert NQuads.Encoder.encode!(Dataset.new [
          {EX.S1, EX.p1, ~L"foo",   EX.G1},
          {EX.S1, EX.p1, ~L"foo"en, EX.G2},
          {EX.S1, EX.p2, 42,        EX.G3},
          {EX.S2, EX.p3, RDF.literal("strange things", datatype: EX.custom), EX.G3},
        ]) ==
        """
        <http://example.org/#S1> <http://example.org/#p1> "foo" <http://example.org/#G1> .
        <http://example.org/#S1> <http://example.org/#p1> "foo"@en <http://example.org/#G2> .
        <http://example.org/#S1> <http://example.org/#p2> "42"^^<#{XSD.integer}> <http://example.org/#G3> .
        <http://example.org/#S2> <http://example.org/#p3> "strange things"^^<#{EX.custom}> <http://example.org/#G3> .
        """
    end

    test "statements with blank nodes" do
      assert NQuads.Encoder.encode!(Dataset.new [
                {EX.S1, EX.p1, RDF.bnode(1)},
                {EX.S1, EX.p1, RDF.bnode("foo"), EX.G},
                {EX.S1, EX.p1, RDF.bnode(:bar)},
              ]) ==
              """
              <http://example.org/#S1> <http://example.org/#p1> _:1 .
              <http://example.org/#S1> <http://example.org/#p1> _:bar .
              <http://example.org/#S1> <http://example.org/#p1> _:foo <http://example.org/#G> .
              """
    end
  end

end
