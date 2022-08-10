local omnisharp_client = require("neotest-dotnet.omnisharp-lsp.client")
local async = require("neotest.async")
local OmnisharpRequests = {}

local omnisharpEndpoints = {
  reanalyze = "o#/reanalyze",
  project = "o#/project",
  projects = "o#/projects",
  codestructure = "o#/v2/codestructure",
  blockstructure = "o#/v2/blockstructure",
  quickinfo = "o#/quickinfo",
  testContext = "o#/gettestcontext",
  testStartInfo = "o#/v2/getteststartinfo",
  debugTestGetStartInfo = "o#/v2/debugtest/getstartinfo",
  debugTestLaunch = "o#/v2/debugtest/launch",
  debugTestStop = "o#/v2/debugtest/stop",
  debugTestsInClassGetStartInfo = "o#/v2/debugtestsinclass/getstartinfo",
  discoverTests = "o#/v2/discovertests",
  signatureHelp = "o#/signaturehelp"
}

local function find_tests_in_file(code_elements, test_list)
  test_list = test_list or {}

  for _, element in ipairs(code_elements) do
    -- Check the elements for tests
    if element.Properties and element.Properties.testMethodName and element.Properties.testFramework then
      table.insert(test_list, element)
    end

    if element.Children then
      find_tests_in_file(element.Children, test_list)
    end
  end

  return test_list
end

local function find_test(tests)
  for _, test in ipairs(tests) do
    local test_ranges = test.Ranges.full
    if async.fn.line(".") >= test_ranges.Start.Line and async.fn.line(".") <= test_ranges.End.Line then
      return test
    end
  end
end

--- Gets the code structure of the current .cs file
---@return table:
---   {
---      Elements = {
---        Children = {
---          Children = {
---           {
---             Displayname: "display name of element"
---             Kind: "type of element. e.g. 'method'",
---             Name: "name of element",
---             Properties = {
---               accessibility?: "optional",
---               static?: "boolean indicating if item is static",
---               testFrameworkName?: "indicates test framework. Only present if this element is a test method",
---               testMethodName?: "Fully qualified test name. Only if this element is test method"
---             },
---             Ranges = {
---               attributes = {
---                 Start = {
---                   Line: "start line of element",
---                   Column: "start column of element"
---                 },
---                 End = {
---                   Line: "end line of element",
---                   Column: "end column of element"
---                 }
---               }
---               full = {
---                 Start = {
---                   Line: "start line of element",
---                   Column: "start column of element"
---                 },
---                 End = {
---                   Line: "end line of element",
---                   Column: "end column of element"
---                 }
---               }
---               name = {
---                 Start = {
---                   Line: "start line of element",
---                   Column: "start column of element"
---                 },
---                 End = {
---                   Line: "end line of element",
---                   Column: "end column of element"
---                 }
---               }
---             }
---           }
---         }
---      }
---   }
function OmnisharpRequests.get_code_structure(file_name)
  local params = omnisharp_client.make_basic_request_params(file_name)

  local response = omnisharp_client.make_request(omnisharpEndpoints.codestructure, params)

  return response.result
end

function OmnisharpRequests.get_tests_in_file(file_name)
  local code_structure = OmnisharpRequests.get_code_structure(file_name)

  local tests = find_tests_in_file(code_structure.Elements)
  return tests
end

function OmnisharpRequests.get_project(file_name, bufnr)
  local params = omnisharp_client.make_basic_request_params(file_name)

  local response = omnisharp_client.make_request(omnisharpEndpoints.project, params, bufnr)
  return response
end

return OmnisharpRequests
