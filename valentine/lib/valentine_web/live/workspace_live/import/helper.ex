defmodule ValentineWeb.WorkspaceLive.Import.Helper do
  alias ValentineWeb.WorkspaceLive.Import.JsonImport
  alias ValentineWeb.WorkspaceLive.Import.TcImport

  def import_file(path, filename, owner) do
    if String.ends_with?(filename, ".tc.json") do
      TcImport.process_tc_file(path, owner)
    else
      JsonImport.process_json_file(path, owner)
    end
  end
end
