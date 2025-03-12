defmodule Mix.Tasks.Phx.New.Yosu do
  use Mix.Task

  def run(args) do
    Mix.Task.load_all()

    # Ensure the task can be re-run
    Mix.Task.reenable("phx.new.yosu")

    case args do
      [] ->
        Mix.raise("Please provide a project name, e.g, mix phx.new.yosu my_app")

      [project_name | phx_args] ->
        # Step 1: Run the default phx.new task
        Mix.Task.run("phx.new", [project_name | phx_args])

        # Step 2: Change directory to the new project
        File.cd!(project_name)

        # Step 3: Apply customizations
        add_custom_dependencies()
        add_styler_plugin()
    end
  end

  defp add_custom_dependencies do
    ast = File.read!("mix.exs") |> Code.string_to_quoted!()

    new_ast =
      Macro.postwalk(ast, fn
        {:defp, meta, [{:deps, _, _} = fun_head, [do: deps_body]]} ->
          # Ensure deps body is a list
          existing_deps =
            case deps_body do
              {:block, _, deps} -> deps
              deps when is_list(deps) -> deps
              dep -> [dep]
            end

          additional_deps = [
            quote do
              {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
            end,
            quote do
              {:styler, "~> 1.4", only: [:dev, :test], runtime: false}
            end,
            quote do
              {:short_uuid, "~> 1.1", github: "yosu/short_uuid"}
            end
          ]

          updated_deps = existing_deps ++ additional_deps

          {:defp, meta, [fun_head, [do: updated_deps]]}

        other ->
          other
      end)

    updated_mix_exs_content = Macro.to_string(new_ast)

    File.write!("mix.exs", updated_mix_exs_content)
  end

  defp add_styler_plugin do
    formatter_content = File.read!(".formatter.exs")

    {formatter_config, _bindings} = Code.eval_string(formatter_content)

    updated_config =
      Keyword.update(formatter_config, :plugins, [Styler], fn existing_plugins ->
        existing_plugins ++ [Styler]
      end)

    updated_content =
      """
      [
      #{formatter_config_to_string(updated_config)}
      ]
      """

    File.write!(".formatter.exs", updated_content)
  end

  defp formatter_config_to_string(config) do
    config
    |> Enum.map(fn {key, value} ->
      "  #{key}: #{inspect(value, pretty: true)}"
    end)
    |> Enum.join(",\n")
  end
end
