# SPDX-FileCopyrightText: 2019 ash_postgres contributors <https://github.com/ash-project/ash_postgres/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPostgres.Test.PostWithVersions do
  @doc false

  use Ash.Resource,
    domain: AshPostgres.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource]

  postgres do
    table "posts_with_versions"
    repo(AshPostgres.TestRepo)
  end

  paper_trail do
    primary_key_type(:uuid)
    change_tracking_mode(:changes_only)
    store_action_name?(true)
    ignore_attributes([:inserted_at, :updated_at])
    attributes_as_attributes([:title])
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, allow_nil?: false, public?: true)
    attribute(:title2, :string, public?: true)

    timestamps()
  end

  actions do
    default_accept(:*)
    defaults([:read, :destroy, :create, :update])

    update :update_with_nested_bulk_update do
      atomic_upgrade?(false)

      change(
        after_action(fn changeset, result, context ->
          other_posts = __MODULE__ |> Ash.read!()

          other_posts
          |> Enum.reject(fn post -> post.id == result.id end)
          |> Ash.bulk_update!(:update, %{title2: "nested_update"},
            notify?: true,
            strategy: :stream,
            return_records?: false
          )

          {:ok, result}
        end)
      )
    end
  end
end
