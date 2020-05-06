defmodule RDF.XSD.UnsignedShortTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.UnsignedShort,
    name: "unsignedShort",
    base: RDF.XSD.UnsignedInt,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [RDF.XSD.Facets.MinInclusive, RDF.XSD.Facets.MaxInclusive],
    facets: %{
      min_inclusive: 0,
      max_inclusive: 65535
    },
    valid: RDF.XSD.TestData.valid_unsigned_shorts(),
    invalid: RDF.XSD.TestData.invalid_unsigned_shorts()
end