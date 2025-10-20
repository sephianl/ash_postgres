# SPDX-FileCopyrightText: 2019 ash_postgres contributors <https://github.com/ash-project/ash_postgres/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshPostgres.TestRepo.Migrations.AddPostsWithoutVersions do
  @moduledoc """
  Adds posts_without_versions table for testing nested bulk updates WITHOUT paper trail.
  """

  use Ecto.Migration

  def up do
    create table(:posts_without_versions, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true
      add :title, :text, null: false
      add :title2, :text
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :updated_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end
  end

  def down do
    drop table(:posts_without_versions)
  end
end