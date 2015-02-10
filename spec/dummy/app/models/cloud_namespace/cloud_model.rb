class CloudNamespace::CloudModel < OceanDynamo::Table

  dynamo_schema(:uuid, create: true) do
    # Nothing needed here, minimal test case for the namespaced table_name
  end

end
