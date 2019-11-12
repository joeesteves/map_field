defmodule MapField do
  @moduledoc """
  Documentation for MapField.
  """
  defmacro fields(field, keys) do
    quote do
      field(unquote(field), :map, default: %{})

      for key <- unquote(keys) do
        field(key, :string, virtual: true)
      end
    end
  end

  defmacro functions(field, keys) do
    populate_function_name = "populate_" <> Atom.to_string(field) |> String.to_atom()
    upsert_function_name = "upsert_" <> Atom.to_string(field) |> String.to_atom()

    quote do
      defp unquote(field)(changeset) do
        changeset
        |> upsert_settings
        |> populate_settings
      end

      defp unquote(populate_function_name)(changeset) do
        Enum.reduce(unquote(keys), changeset, fn field, changeset ->
          settings = get_field(changeset, :settings)

          change(changeset, [
            {field, Map.get(settings, Atom.to_string(field))}
          ])
        end)
      end

      defp unquote(upsert_function_name)(changeset) do
        case unquote(keys) -- unquote(keys) -- Map.keys(changeset.changes) do
          [] ->
            changeset

          changed_keys ->
            Enum.reduce(changed_keys, changeset, fn changed_field, changeset ->
              settings = get_field(changeset, :settings)

              change(changeset,
                settings:
                  Map.put(
                    settings,
                    Atom.to_string(changed_field),
                    Map.get(changeset.changes, changed_field) |> IO.inspect()
                  )
              )
            end)
        end
      end
    end
  end
end
