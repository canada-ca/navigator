defmodule Valentine.RepoAnalysis.GitHubTest do
  use Valentine.DataCase

  alias Valentine.RepoAnalysis.GitHub
  alias Valentine.RepoAnalysis.GitHub.RepoRef

  describe "clone/3" do
    test "removes the clone directory when the clone command times out" do
      temp_dir =
        Path.join(
          System.tmp_dir!(),
          "repo-analysis-github-test-#{System.unique_integer([:positive])}"
        )

      fake_bin_dir = Path.join(temp_dir, "bin")
      clone_root = Path.join(temp_dir, "clones")
      fake_git_path = Path.join(fake_bin_dir, "git")
      original_path = System.get_env("PATH") || ""

      File.mkdir_p!(fake_bin_dir)
      File.mkdir_p!(clone_root)

      File.write!(
        fake_git_path,
        "#!/bin/sh\nlast=\"\"\nfor arg in \"$@\"; do\n  last=\"$arg\"\ndone\nmkdir -p \"$last\"\nprintf 'partial clone' > \"$last/partial.txt\"\nsleep 1\n"
      )

      File.chmod!(fake_git_path, 0o755)
      System.put_env("PATH", fake_bin_dir <> ":" <> original_path)

      on_exit(fn ->
        System.put_env("PATH", original_path)
        File.rm_rf(temp_dir)
      end)

      repo_ref = %RepoRef{
        owner: "example",
        name: "platform-api",
        full_name: "example/platform-api",
        clone_url: "https://github.com/example/platform-api.git"
      }

      assert_raise RuntimeError, ~r/Command timed out after 50ms/, fn ->
        GitHub.clone(repo_ref, "job-123", %{
          "working_dir" => clone_root,
          "clone_timeout_ms" => 50
        })
      end

      refute File.exists?(Path.join(clone_root, "job-123"))
    end
  end
end
