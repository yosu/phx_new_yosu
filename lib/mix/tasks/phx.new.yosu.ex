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
        create_custom_schema_file(project_name)
        update_config_file(project_name)
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

  defp create_custom_schema_file(project_name) do
    module_name = Macro.camelize(project_name)

    file_content = """
    defmodule #{module_name}.Schema do
      @moduledoc false
      defmacro __using__(opts) do
        quote do
          use Ecto.Schema

          unquote(primary_key(opts[:prefix]))
          @foreign_key_type ShortUUID
          @timestamps_opts [type: :utc_datetime_usec]
        end
      end

      defp primary_key(prefix) when is_binary(prefix) do
        quote do
          @primary_key {:id, ShortUUID, autogenerate: true, prefix: unquote(prefix)}
        end
      end

      defp primary_key(_) do
        quote do
          @primary_key {:id, ShortUUID, autogenerate: true}
        end
      end
    end
    """

    # Ensure the directory exists
    File.mkdir_p!("lib/#{project_name}")

    File.write!("lib/#{project_name}/schema.ex", file_content)
  end

  defp update_config_file(project_name) do
    module_name = Macro.camelize(project_name)
    app_name = project_name

    config_file = "config/config.exs"
    config_content = File.read!(config_file)

    # Replace the existing config block

    # Define the regex pattern to match the existing config block
    # We'll match 'config :my_app,' and any following lines until the next 'config' keyword or empty line
    config_pattern = ~r/^config\s+:#{app_name},\s*\n(?:\s+.*\n)*?(?=^\s*(config|#|$))/m

    # Build the new config block
    new_config = """
    config :#{app_name},
      ecto_repos: [#{module_name}.Repo],
      generators: [timestamp_type: :utc_datetime_usec]

    config :#{app_name}, #{module_name}.Repo,
      migration_primary_key: [type: :string],
      migration_foreign_key: [type: :string],
      migration_timestamps: [type: :utc_datetime_usec]
    """

    updated_config_content =
      if Regex.match?(config_pattern, config_content) do
        # Replace the existing block
        Regex.replace(config_pattern, config_content, new_config)
      else
        # If the existing block is not found, we can add the new config at the top
        new_config <> "\n" <> config_content
      end

    # Write back the updated config file
    File.write!(config_file, updated_config_content)
  end
end
