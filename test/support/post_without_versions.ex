# SPDX-FileCopyrightText: 2019 ash_postgres contributors <https://github.com/ash-project/ash_postgres/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPostgres.Test.PostWithoutVersions do
  @moduledoc """
  Test resource for nested bulk updates WITHOUT paper trail to isolate the bug.
  """

  use Ash.Resource,
    domain: AshPostgres.Test.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "posts_without_versions"
    repo AshPostgres.TestRepo
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, allow_nil?: false)
    attribute(:title2, :string)

    timestamps()
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:title, :title2])
    end

    update :update do
      primary?(true)
      accept([:title, :title2])
    end

    update :update_with_nested_bulk_update do
      accept([])
      atomic_upgrade?(false)
      require_atomic?(false)

      change(
        after_action(fn changeset, result, context ->
          # This is the same nested bulk update pattern as PostWithVersions
          # but WITHOUT AshPaperTrail to test if the bug is in paper trail or nested updates
          other_posts = __MODULE__ |> Ash.read!()

          other_posts
          |> Enum.reject(fn post -> post.id == result.id end)
          |> Ash.bulk_update!(:update, %{title2: "nested_update"},
            notify?: true,
            strategy: :stream,
            return_records?: false,
            domain: AshPostgres.Test.Domain,
            resource: __MODULE__
          )

          {:ok, result}
        end)
      )
    end
  end
end
