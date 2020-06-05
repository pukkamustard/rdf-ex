defmodule RDF.Query.BGP.SimpleTest do
  use RDF.Test.Case

  alias RDF.Query.BGP
  import RDF.Query.BGP.Simple, only: [query: 2]

  @example_graph Graph.new([
    {EX.s1, EX.p1, EX.o1},
    {EX.s1, EX.p2, EX.o2},
    {EX.s3, EX.p3, EX.o2}
  ])

  test "empty bgp" do
    assert query(@example_graph, []) == [%{}]
  end

  test "single {s ?p ?o}" do
    assert query(@example_graph, [{EX.s1, "p", "o"}]) ==
               [
                 %{"p" => EX.p1, "o" => EX.o1},
                 %{"p" => EX.p2, "o" => EX.o2}
               ]
  end

  test "single {?s ?p o}" do
    assert query(@example_graph, [{"s", "p", EX.o2}]) ==
               [
                 %{"s" => EX.s3, "p" => EX.p3},
                 %{"s" => EX.s1, "p" => EX.p2}
               ]
  end

  test "single {?s p ?o}" do
    assert query(@example_graph, [{"s", EX.p3, "o"}]) == [%{"s" => EX.s3, "o" => EX.o2}]
  end

  test "with no solutions" do
    assert query(Graph.new(), [{"a", "b", "c"}]) == []
  end

  test "with solutions on one triple pattern but none on another one" do
    example_graph = Graph.new([
      {EX.x, EX.y, EX.z},
      {EX.y, EX.y, EX.z},
    ])

    assert query(example_graph, [
             {"a", EX.p1, ~L"unmatched" },
             {"a", EX.y, EX.z}
           ]) == []
  end

  test "repeated variable: {?a ?a ?b}" do
    example_graph = Graph.new([
      {EX.y, EX.y, EX.x},
      {EX.x, EX.y, EX.y},
      {EX.y, EX.x, EX.y}
    ])

    assert query(example_graph, [{"a", "a", "b"}]) == [%{"a" => EX.y, "b" => EX.x}]
  end

  test "repeated variable: {?a ?b ?a}" do
    example_graph = Graph.new([
      {EX.y, EX.y, EX.x},
      {EX.x, EX.y, EX.y},
      {EX.y, EX.x, EX.y}
    ])

    assert query(example_graph, [{"a", "b", "a"}]) == [%{"a" => EX.y, "b" => EX.x}]
  end

  test "repeated variable: {?b ?a ?a}" do
    example_graph = Graph.new([
      {EX.y, EX.y, EX.x},
      {EX.x, EX.y, EX.y},
      {EX.y, EX.x, EX.y}
    ])

    assert query(example_graph, [{"b", "a", "a"}]) == [%{"a" => EX.y, "b" => EX.x}]
  end

  test "repeated variable: {?a ?a ?a}" do
    example_graph = Graph.new([
      {EX.y, EX.y, EX.x},
      {EX.x, EX.y, EX.y},
      {EX.y, EX.x, EX.y},
      {EX.y, EX.y, EX.y},
    ])

    assert query(example_graph, [{"a", "a", "a"}]) == [%{"a" => EX.y}]
  end

  test "two connected triple patterns with a match" do
    assert query(@example_graph, [
             {EX.s1, "p", "o"},
             {EX.s3, "p2", "o" }
           ]) == [%{
             "p"  => EX.p2,
             "p2" => EX.p3,
             "o"  => EX.o2
           }]

    assert query(@example_graph, [
             {EX.s1, "p", "o1"},
             {EX.s1, "p", "o2"}
           ]) ==
               [
                 %{
                   "p"  => EX.p1,
                   "o1" => EX.o1,
                   "o2" => EX.o1,
                 },
                 %{
                   "p"  => EX.p2,
                   "o1" => EX.o2,
                   "o2" => EX.o2,
                 },
               ]

    assert query(
             Graph.new([
               {EX.s1, EX.p1, EX.o1},
               {EX.s3, EX.p2, EX.o2},
               {EX.s3, EX.p3, EX.o1}
             ]),
             [
               {EX.s1, EX.p1, "o"},
               {EX.s3, "p", "o"}
             ]) == [%{"p"  => EX.p3, "o"  => EX.o1}]
  end

  test "a triple pattern with dependent variables from separate triple patterns" do
    assert query(
             Graph.new([
               {EX.s1, EX.p1, EX.o1},
               {EX.s2, EX.p2, EX.o2},
               {EX.s3, EX.p2, EX.o1}
             ]),
             [
               {EX.s1, EX.p1, "o"},
               {EX.s2, "p", EX.o2},
               {"s", "p", "o"}
             ]
           ) == [
             %{
               "s" => EX.s3,
               "p" => EX.p2,
               "o" => EX.o1,
             },
           ]
  end

  test "when no solutions" do
    assert query(@example_graph, [{EX.s, EX.p, "o"}]) == []
  end

  test "multiple triple patterns with a constant unmatched triple has no solutions" do
    assert query(@example_graph, [
             {EX.s1, "p", "o"},
             {EX.s, EX.p, EX.o}
           ]) == []
  end

  test "independent triple patterns lead to cross-products" do
    assert query(@example_graph, [
             {EX.s1, "p1", "o"},
             {"s", "p2", EX.o2}
           ]) == [
                 %{
                   "p1" => EX.p1,
                   "o"  => EX.o1,
                   "s"  => EX.s3,
                   "p2" => EX.p3,
                 },
                 %{
                   "p1" => EX.p2,
                   "o"  => EX.o2,
                   "s"  => EX.s3,
                   "p2" => EX.p3,
                 },
                 %{
                   "p1" => EX.p1,
                   "o"  => EX.o1,
                   "s"  => EX.s1,
                   "p2" => EX.p2,
                 },
                 %{
                   "p1" => EX.p2,
                   "o"  => EX.o2,
                   "s"  => EX.s1,
                   "p2" => EX.p2,
                 },
               ]
  end

  test "blank nodes behave like variables, but don't appear in the solution" do
    assert query(@example_graph, [
             {EX.s1, "p", RDF.bnode("o")},
             {EX.s3, "p2", RDF.bnode("o")}
           ]) == [%{"p" => EX.p2, "p2" => EX.p3}]
  end

  test "cross-product with blank nodes" do
    assert query(@example_graph, [
             {EX.s1, "p1", "o"},
             {RDF.bnode("s"), "p2", EX.o2}
           ]) ==
               [
                 %{
                   "p1" => EX.p1,
                   "o"  => EX.o1,
                   "p2" => EX.p3,
                 },
                 %{
                   "p1" => EX.p2,
                   "o"  => EX.o2,
                   "p2" => EX.p3,
                 },
                 %{
                   "p1" => EX.p1,
                   "o"  => EX.o1,
                   "p2" => EX.p2,
                 },
                 %{
                   "p1" => EX.p2,
                   "o"  => EX.o2,
                   "p2" => EX.p2,
                 },
               ]
  end

  describe "Planner.query_plan/1" do
    alias BGP.Simple.Planner

    test "empty" do
      assert Planner.query_plan([]) == []
    end

    test "single" do
      assert Planner.query_plan([{"a", "b", "c"}]) == [{"a", "b", "c"}]
    end

    test "multiple connected" do
      assert Planner.query_plan([
               {"a", "b", "c"},
               {"a", "d", ~L"foo"}
             ]) == [
               {"a", "d", ~L"foo"},
               {{"a"}, "b", "c"}
             ]

      assert Planner.query_plan([
               {"s", "p", "o"},
               {"s2", "p2", "o2"},
               {"s", "p", "o2"},
               {"s4", "p4", ~L"foo"}
             ]) == [
               {"s4", "p4", ~L"foo"},
               {"s", "p", "o"},
               {{"s"}, {"p"}, "o2"},
               {"s2", "p2", {"o2"}},
             ]
    end
  end
end
