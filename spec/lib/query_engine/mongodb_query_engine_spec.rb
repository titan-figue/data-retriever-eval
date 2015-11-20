require "spec_helper"

describe MongoQueryEngine do
  let(:qe) { MongoQueryEngine.new({}) }
  let(:match_query) do
    <<-REQ.gsub(/^ {4}/, "")
    {
      "collection": "metrics",
      "query": [
        {
          "operator": "aggregate",
          "pipeline":[
            #_match_f1_#
            {
              "$group": {
                "_id": { "year": "$year", "month": "$month"},
                "value": { "$sum": "$sessions"}
              }
            },
            {
              "$project": {
                "_id": 0,
                "category": "$_id.month",
                "serie": "$_id.year",
                "value": "$value"
              }
            },
            {
              "$sort": {
                "category": 1,
                "serie": 1
              }
            }
          ]
        }
      ]
    }
    REQ
  end
  let(:find_query) do
    <<-REQ.gsub(/^ {4}/, "")
    {
      "collection": "metrics",
      "query": [
        {
          "operator": "find",
          "filter": {#_find_f1_#},
          "opts": {
            "$sort": {
              "year": 1,
              "month": 1,
              "day": 1
            }
          }
        }
      ]
    }
    REQ
  end
  let(:and_query) do
    <<-REQ.gsub(/^ {4}/, "")
    {
      "collection": "metrics",
      "query": [
        {
          "operator": "find",
          "filter": {"$and": [{ "year": 2014 } #_and_f1_#]},
          "opts": {
            "$sort": {
              "year": 1,
              "month": 1,
              "day": 1
            }
          }
        }
      ]
    }
    REQ
  end
  let(:find_query_with_params) do
    <<-REQ.gsub(/^ {4}/, "")
    {
      "collection": "metrics",
      "query": [
        {
          "operator": "find",
          "filter": {#_find_f1_#},
          "opts": {
            "$sort": {
              "#_params1_#": 1,
              "month": 1,
              "day": 1
            }
          }
        }
      ]
    }
    REQ
  end
  let(:filter_array) do
    {
      "match_f1" => [
        { operator: "$gte", value: "20130101", field: "datestamp", value_type: "int" },
        { operator: "$lte", value: "20151231", field: "datestamp", value_type: "int" },
        { operator: "$eq", value: "2014", field: "year", value_type: "string" }
      ],
      "find_f1" => [
        { operator: "$gte", value: "20130101", field: "datestamp", value_type: "int" },
        { operator: "$lte", value: "20151231", field: "datestamp", value_type: "int" }
      ],
      "and_f1" => [
        { operator: "$gte", value: "20130101", field: "datestamp", value_type: "int" },
        { operator: "$lte", value: "20151231", field: "datestamp", value_type: "int" }
      ]
    }
  end

  let(:empty_filter_array) do
    {
      "match_f1" => [],
      "find_f1" => [],
      "and_f1" => []
    }
  end
  let(:client) { "test_client" }
  let(:query_params) { { "params1" => "year" } }

  context "decorate" do
    describe "for match" do
      context "with filters" do
        let(:match_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "aggregate",
                "pipeline" => [
                  { "$match" => { "$and" => [{ "datestamp" => { "$gte" => 2013_01_01 } }, { "datestamp" => { "$lte" => 2015_12_31 } }, { "year" => "2014" }] } },
                  {
                    "$group" => {
                      "_id" => { "year" => "$year", "month" => "$month" },
                      "value" => { "$sum" => "$sessions" }
                    }
                  },
                  {
                    "$project" => {
                      "_id" => 0,
                      "category" => "$_id.month",
                      "serie" => "$_id.year",
                      "value" => "$value"
                    }
                  },
                  {
                    "$sort" => {
                      "category" => 1,
                      "serie" => 1
                    }
                  }
                ]
              }
            ]
          }
        end

        it { expect(qe.decorate(match_query, client, filter_array)).to eq(match_query_res) }
      end

      context "without filters" do
        let(:match_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "aggregate",
                "pipeline" => [
                  {
                    "$group" => {
                      "_id" => { "year" => "$year", "month" => "$month" },
                      "value" => { "$sum" => "$sessions" }
                    }
                  },
                  {
                    "$project" => {
                      "_id" => 0,
                      "category" => "$_id.month",
                      "serie" => "$_id.year",
                      "value" => "$value"
                    }
                  },
                  {
                    "$sort" => {
                      "category" => 1,
                      "serie" => 1
                    }
                  }
                ]
              }
            ]
          }
        end

        it { expect(qe.decorate(match_query, client)).to eq(match_query_res) }
      end

      context "with empty filters" do
        let(:match_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "aggregate",
                "pipeline" => [
                  {
                    "$group" => {
                      "_id" => { "year" => "$year", "month" => "$month" },
                      "value" => { "$sum" => "$sessions" }
                    }
                  },
                  {
                    "$project" => {
                      "_id" => 0,
                      "category" => "$_id.month",
                      "serie" => "$_id.year",
                      "value" => "$value"
                    }
                  },
                  {
                    "$sort" => {
                      "category" => 1,
                      "serie" => 1
                    }
                  }
                ]
              }
            ]
          }
        end

        it { expect(qe.decorate(match_query, client, empty_filter_array)).to eq(match_query_res) }
      end
    end

    describe "for find" do
      context "with filters" do
        let(:find_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "find",
                "filter" => { "$and" => [{ "datestamp" => { "$gte" => 2013_01_01 } }, { "datestamp" => { "$lte" => 2015_12_31 } }] },
                "opts" => {
                  "$sort" => {
                    "year" => 1,
                    "month" => 1,
                    "day" => 1
                  }
                }
              }
            ]
          }
        end

        it { expect(qe.decorate(find_query, client, filter_array)).to eq(find_query_res) }
      end

      context "without filters" do
        let(:find_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "find",
                "filter" => {},
                "opts" => {
                  "$sort" => {
                    "year" => 1,
                    "month" => 1,
                    "day" => 1
                  }
                }
              }
            ]
          }

        end

        it { expect(qe.decorate(find_query, client)).to eq(find_query_res) }
      end

      context "with empty filters" do
        let(:find_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "find",
                "filter" => {},
                "opts" => {
                  "$sort" => {
                    "year" => 1,
                    "month" => 1,
                    "day" => 1
                  }
                }
              }
            ]
          }
        end

        it { expect(qe.decorate(find_query, client, empty_filter_array)).to eq(find_query_res) }
      end
    end

    describe "for and" do
      context "with filters" do
        let(:and_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "find",
                "filter" => { "$and" => [{ "year" => 2014 }, { "datestamp" => { "$gte" => 2013_01_01 } }, { "datestamp" => { "$lte" => 2015_12_31 } }] },
                "opts" => {
                  "$sort" => {
                    "year" => 1,
                    "month" => 1,
                    "day" => 1
                  }
                }
              }
            ]
          }
        end

        it { expect(qe.decorate(and_query, client, filter_array)).to eq(and_query_res) }
      end

      context "without filters" do
        let(:and_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "find",
                "filter" => { "$and" => [{ "year" => 2014 }] },
                "opts" => {
                  "$sort" => {
                    "year" => 1,
                    "month" => 1,
                    "day" => 1
                  }
                }
              }
            ]
          }
        end

        it { expect(qe.decorate(and_query, client)).to eq(and_query_res) }
      end

      context "with empty filters" do
        let(:and_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "find",
                "filter" => { "$and" => [{ "year" => 2014 }] },
                "opts" => {
                  "$sort" => {
                    "year" => 1,
                    "month" => 1,
                    "day" => 1
                  }
                }
              }
            ]
          }
        end

        it { expect(qe.decorate(and_query, client, empty_filter_array)).to eq(and_query_res) }
      end
    end

    describe "for find with query params" do
      context "with filters" do
        let(:find_query_res) do
          {
            "collection" => "metrics",
            "query" => [
              {
                "operator" => "find",
                "filter" => { "$and" => [{ "datestamp" => { "$gte" => 2013_01_01 } }, { "datestamp" => { "$lte" => 2015_12_31 } }] },
                "opts" => {
                  "$sort" => {
                    "year" => 1,
                    "month" => 1,
                    "day" => 1
                  }
                }
              }
            ]
          }
        end

        it { expect(qe.decorate(find_query, client, filter_array, query_params)).to eq(find_query_res) }
      end
    end
  end
end
